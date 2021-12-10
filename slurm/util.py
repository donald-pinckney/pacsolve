import json
from typing import List, Any, Iterable
from more_itertools import chunked, distribute

def remove_nones(seq):
    return [x for x in seq if x is not None]

class suppressed_iterator:
    def __init__(self, wrapped_iter, skipped_exc = Exception):
        self.wrapped_iter = wrapped_iter
        self.skipped_exc  = skipped_exc

    def __iter__(self):
        return self

    def __next__(self):
        while True:
            try:
                return next(self.wrapped_iter)
            except StopIteration:
                raise
            except self.skipped_exc as exn:
                print(f'Skipped exception {exn}')
                pass

def write_json(path, data):
    with open(path, 'wt') as out:
        out.write(json.dumps(data))

def read_json(path: str) -> any:
    with open(path, 'r') as f_in:
        return json.load(f_in)

def chunked_or_distributed(
    items: Iterable[Any],
    max_groups: int,
    optimal_group_size: int) -> Iterable[Iterable[Any]]:
    """Divide *items* into at most *max_groups*. If possible, produces fewer
    than *max_groups*, but with at most *optimal_group_size* items in each
    group."""
    if len(items) / optimal_group_size <= max_groups:
        return chunked(items, optimal_group_size)
    else:
        return distribute(items, max_groups)
