open Unix
open Filename
open Str
open Printf
open OUnit2
open ExtLib

let result_printer (e : (string, string) result) : string =
  match e with
  | Error v -> sprintf "Error: %s\n" v
  | Ok v -> v

(* Read a file into a string *)
let string_of_file (file_name : string) : string =
  let inchan = open_in file_name in
  let ans = really_input_string inchan (in_channel_length inchan) in
  close_in inchan; ans

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

let run (filename : string) : (string, string) result =
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
  let _, status = waitpid [] ran_pid in
  let result =
    match status with
    | WEXITED 0 -> Ok (string_of_file ("../../actual/" ^ filename))
    | WEXITED n -> Error (sprintf "Exited with %d: %s" n (string_of_file rstderr_name))
    | WSIGNALED n -> Error (sprintf "Signalled with %d while running %s." n filename)
    | WSTOPPED n -> Error (sprintf "Stopped with signal %d while running %s." n filename)
  in
  List.iter close [rstdout; rstderr; rstdin];
  List.iter unlink [rstdout_name; rstderr_name];
  result

let test_run (name : string) (test_ctxt : OUnit2.test_ctxt) : unit =
  let filename = name ^ ".json" in
  let expected = string_of_file ("../../expected/" ^ filename) in
  let result = run filename in
  assert_equal (Ok expected) result ~printer:result_printer
