import os
from typing import Dict, List, Optional, Tuple
from json_loading import load_semver_version

from program_ast.version import SemverVersion, Version
from solver.base import Registry, Solver
from solver.solve_result import SolutionGraph, RootContextVertex, ResolvedPackageVertex, SolveError
from program_ast.dependency import Dependency
import json
import tempfile
import subprocess


def parse_vertex_json(j):
  if j['type'] == 'RootContextVertex':
    return RootContextVertex()
  elif j['type'] == 'ResolvedPackageVertex':
    return ResolvedPackageVertex(j['package'], load_semver_version(j['version']))
  else:
    raise SolveError("Unknown vertex type: " + j['type'])

class RosetteSolver(Solver):
  def solve(self, previous_solution: Optional[SolutionGraph], dependencies: List[Dependency], registry: Registry) -> SolutionGraph:
    rosette_reg: Dict[str, List[Tuple[Version, List[Dependency]]]] = dict()
    for (p, v) in registry.keys():
      if p not in rosette_reg:
        rosette_reg[p] = []

      rosette_reg[p].append((v, registry[(p, v)]))
    
    # reg_by_packages = { for p in packages}

    rosette_reg_json = [{
      "package": p, 
      "versions": [{
          "version": v.to_json(), 
          "dependencies": [d.to_json() for d in deps]
        } for (v, deps) in rosette_reg[p]]} for p in rosette_reg]

    

    rosette_context_deps = [d.to_json() for d in dependencies]

    rosette_input_json = {"registry": rosette_reg_json, "context_dependencies": rosette_context_deps}

    rosette_in_path = tempfile.mktemp()
    rosette_out_path = tempfile.mktemp()
    
    with open(rosette_in_path, 'w') as rosette_in_f:
      json.dump(rosette_input_json, rosette_in_f)
    
    subprocess.check_call(["racket", "RosetteSolver/rosette-solver.rkt", rosette_in_path, rosette_out_path])

    with open(rosette_out_path, 'r') as rosette_out_f:
      out_json = json.load(rosette_out_f)
    
    os.remove(rosette_in_path)
    os.remove(rosette_out_path)

    if not out_json['success']:
      raise SolveError(out_json['error'])

    graph_json = out_json['graph']
    context_vertex = graph_json['context_vertex']
    vertices = [parse_vertex_json(j) for j in graph_json['vertices']]
    
    edge_dict = dict(enumerate(graph_json['out_edge_array']))
    
    return SolutionGraph(vertices, context_vertex, edge_dict)
    
    
    