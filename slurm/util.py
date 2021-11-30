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
