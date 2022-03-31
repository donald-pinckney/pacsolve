open Yojson

(* major, minor, bug, prerelease *)
type version = int * int * int * int

(* package name, package type, version *)
type package = string * version

(* vertices type, packages *)
type vertices = package list

(* context vertex i, edges, vertices, success bool *)
type graph = int * int list list * vertices * bool

let parse_to_graph (json_string : string) : (graph, string) result =
  let json = Basic.from_string json_string in
  let open Basic.Util in
  let success = json |> member "success" |> to_bool in
  if not success
  then
    let error = json |> member "error" |> to_string in
    Error error
  else
    let graph = json |> member "graph" in
    let ctx_vertex = graph |> member "context_vertex" |> to_int in
    let edges_list = graph |> member "out_edge_array" |> to_list in
    let edges_parsed =
      List.map (fun edges -> List.map (fun edge -> edge |> to_int) (edges |> to_list)) edges_list
    in
    let vertices = graph |> member "vertices" |> to_list in
    let packages =
      List.map
        (fun pkg ->
          let get_ver sec = pkg |> member "version" |> member sec |> to_int in
          let name = pkg |> member "package" |> to_string in
          (name, (get_ver "major", get_ver "minor", get_ver "bug", get_ver "prerelease")) )
        (List.tl vertices)
    in
    Ok (ctx_vertex, edges_parsed, packages, success)

(* TODO: figure out ctx_vertex situatio *)
let graph_to_dotgraph ((ctx_vertex, edges_list, packages, _) : graph) : string =
  let prelude, postlude = ("digraph {\n", "}") in
  let root_node = Printf.sprintf "\t0 [ label = \"Root\" ]\n" in
  let nodes_str =
    String.concat ""
      (List.mapi
         (fun i (name, (major, minor, bug, pre)) ->
           Printf.sprintf "\t%d [ label = \"%s v%d.%d.%d-%d\" ]\n" (i + 1) name major minor bug pre
           )
         packages )
  in
  let edges_str =
    String.concat ""
      (List.mapi
         (fun i edges ->
           String.concat "" (List.map (fun edge -> Printf.sprintf "\t%d -> %d []\n" i edge) edges)
           )
         edges_list )
  in
  prelude ^ root_node ^ nodes_str ^ edges_str ^ postlude

(* EOF  *)
