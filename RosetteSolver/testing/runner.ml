open Unix
open Filename
open Graph
open Str
open Printf
open OUnit2
open ExtLib

let () = OUnitThreads.init ()

let result_printer (e : ('a, string) result) : string =
  match e with
  | Error v -> sprintf "Error: %s\n" v
  | Ok v -> ExtLib.dump v

(* Read a file into a string *)
let string_of_file (file_name : string) : string =
  let inchan = open_in file_name in
  let ans = really_input_string inchan (in_channel_length inchan) in
  close_in inchan; ans

let make_dotgraph_file (filename : string) (graph : graph) : unit =
  let oc = open_out filename in
  let dotgraph = graph_to_dotgraph graph in
  Printf.fprintf oc "%s" dotgraph; close_out oc

type tempfiles =
  Unix.file_descr
  * string (* stdout file and name *)
  * Unix.file_descr
  * string (* stderr file and name *)
  * Unix.file_descr (* stdin file *)

let make_tmpfiles (name : string) (std_input : string) : tempfiles =
  let stdin_read, stdin_write = pipe () in
  let stdout_name = temp_file ("stdout_" ^ name) ".out" in
  let stderr_name = temp_file ("stderr_" ^ name) ".err" in
  ignore (Unix.write_substring stdin_write std_input 0 (String.length std_input));
  Unix.close stdin_write;
  ( openfile stdout_name [O_RDWR] 0o600,
    stdout_name,
    openfile stderr_name [O_RDWR] 0o600,
    stderr_name,
    stdin_read )

let run (filename : string) (timeout : int) : (graph, string) result =
  let result =
    try
      let rstdout, rstdout_name, rstderr, rstderr_name, rstdin = make_tmpfiles "run" "" in
      let ran_pid =
        (* TODO : fix this whole relpath funny business*)
        Unix.create_process "racket"
          (Array.of_list
             [ "racket";
               "../../../rosette-solver.rkt";
               "../../input/" ^ filename;
               "../../actual/" ^ filename ] )
          rstdin rstdout rstderr
      in
      (* creates a signal handler, that will kill the ran_pid if it gets the sigalrm signal. *)
      let sighandler =
        Sys.signal Sys.sigalrm (Sys.Signal_handle (fun _ -> Unix.kill ran_pid Sys.sigterm))
      in
      (* send sigalrm after timeout seconds *)
      let _ = Unix.alarm timeout in
      let result =
        try
          let _, status = waitpid [] ran_pid in
          match status with
          | WEXITED 0 -> (
              let path = "../../actual/" ^ filename in
              match parse_to_graph (string_of_file path) with
              | Ok graph ->
                  make_dotgraph_file (path ^ ".dot") graph;
                  Ok graph
              | Error msg -> Error msg )
          | WEXITED n -> Error (sprintf "Exited with %d: %s" n (string_of_file rstderr_name))
          | WSIGNALED n -> Error (sprintf "Signalled with %d while running %s." n filename)
          | WSTOPPED n -> Error (sprintf "Stopped with signal %d while running %s." n filename)
        with Unix.Unix_error (Unix.EINTR, _, _) ->
          Sys.set_signal Sys.sigalrm sighandler;
          Error (sprintf "Timedout (timeout = %d) while running %s" timeout filename)
      in
      List.iter close [rstdout; rstderr; rstdin];
      List.iter unlink [rstdout_name; rstderr_name];
      result
    with Unix.Unix_error (err, _, _) ->
      Error (sprintf "Unexpected error: %s while running %s" (Unix.error_message err) filename)
  in
  result

type pass_fail =
  | TestPass
  | TestFail

let test_run_pass_fail
    (name : string)
    (timeout : int)
    (pf : pass_fail)
    (test_ctxt : OUnit2.test_ctxt) : unit =
  let filename = name ^ ".json" in
  let output = run filename timeout in
  let result_pf, msg =
    match output with
    | Ok _ -> (TestPass, "")
    | Error err -> (TestFail, err)
  in
  assert_equal pf result_pf ~printer:(fun e ->
      match e with
      | TestPass -> "Test passed"
      | TestFail -> "Test failed: " ^ msg )

let test_run (name : string) (timeout : int) (test_ctxt : OUnit2.test_ctxt) : unit =
  let filename = name ^ ".json" in
  let expected = parse_to_graph (string_of_file ("../../expected/" ^ filename)) in
  let result = run filename timeout in
  assert_equal expected result ~printer:result_printer

let test_run_error
    (name : string)
    (error_msg : string)
    (timeout : int)
    (test_ctxt : OUnit2.test_ctxt) : unit =
  let filename = name ^ ".json" in
  let result = run filename timeout in
  assert_equal (Error error_msg) result ~printer:result_printer ~cmp:(fun check result ->
      match (check, result) with
      (* if a part of the expected string is contained inside the actual string *)
      | Error e_msg, Error a_msg -> String.exists a_msg e_msg
      | _ -> false )
