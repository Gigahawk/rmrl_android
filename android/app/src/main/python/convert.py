import os
import io
from rmrl import render

class ChaquopySource:
    def __init__(self, uuid):
        self.doc_id = uuid
        self.files = {}

    def format_path(self, path):
        return path.format(ID=self.doc_id)

    def insert_file(self, path, data):
        data = bytes(data)
        self.files[path] = data

    def exists(self, path):
        path = self.format_path(path)
        print(f"Checking if path {path} exists")
        e = path in self.files.keys()
        print(e)
        return e

    def open(self, path, mode='r'):
        path = self.format_path(path)
        print(f"Opening path {path} as {mode}")

        if mode == 'r':
            return io.StringIO(self.files[path].decode())
        if mode == 'rb':
            return io.BytesIO(self.files[path])
        raise ValueError('Writing is not supported')

def convert(source):
    print("converting")
    stream = render(
        source,
        template_alpha=0.3,
        expand_pages=True,
        only_annotated=False)
    print("converted")
    print(stream)
    print(type(stream))
    value = stream.read()
    out_path = os.path.join(os.environ["HOME"], "test.pdf")
    print(f"Writing to pdf to {out_path}")
    with open(out_path, 'wb') as f:
        f.write(value)
    return value



