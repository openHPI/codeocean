#!/usr/bin/python3
# Main interpreter entry for webpython
import io, select, sys, os, threading, code
import pickle, struct, builtins, json
#, ressource
from queue import Queue
from argparse import ArgumentParser

# hard limit to 64M
#try:
#    resource.setrlimit(resource.RLIMIT_AS, (1<<26, 1<<26))
#except ValueError:
    # tried to raise it
#    pass

# output limit 16MiB
output_capacity = 16*1024*1024
# adapted from IDLE (PyShell.py)
class PseudoFile(io.TextIOBase):

    def __init__(self, shell, name):
        self.shell = shell
        self._name = name

    @property
    def encoding(self):
        return "UTF-8"

    @property
    def name(self):
        return '<%s>' % self._name

    def isatty(self):
        return True

class PseudoInputFile(PseudoFile):

    def __init__(self, shell, name):
        PseudoFile.__init__(self, shell, name)
        self._line_buffer = ''

    def readable(self):
        return True

    def read(self, size=-1):
        if self.closed:
            raise ValueError("read from closed file")
        if size is None:
            size = -1
        elif not isinstance(size, int):
            raise TypeError('must be int, not ' + type(size).__name__)
        result = self._line_buffer
        self._line_buffer = ''
        if size < 0:
            while True:
                line = self.shell.readline()
                if not line: break
                result += line
        else:
            while len(result) < size:
                line = self.shell.readline()
                if not line: break
                result += line
            self._line_buffer = result[size:]
            result = result[:size]
        return result

    def readline(self, size=-1):
        if self.closed:
            raise ValueError("read from closed file")
        if size is None:
            size = -1
        elif not isinstance(size, int):
            raise TypeError('must be int, not ' + type(size).__name__)
        line = self._line_buffer or self.shell.readline()
        if size < 0:
            size = len(line)
        self._line_buffer = line[size:]
        return line[:size]

    def close(self):
        self.shell.close()

class PseudoOutputFile(PseudoFile):

    def writable(self):
        return True

    def write(self, s):
        if self.closed:
            raise ValueError("write to closed file")
        if not isinstance(s, str):
            raise TypeError('must be str, not ' + type(s).__name__)
        return self.shell.write(s, self._name)

# RPC proxy
orig_stdin = sys.stdin
orig_stdout = sys.stdout
orig_stderr = sys.stderr
class Shell:
    def __init__(self):
        self.stdin = io.FileIO(0)
        self.buf = b''
        self.canvas = []
        self.messages = []
        self.capacity = output_capacity

    # PseudoFile interaction
    #def readline(self):
    #    self.sendpickle({'cmd':'readline',
    #                     'stream':'stdin',
    #                     })
    #    return self.inputq.get()

    def write(self, data, name):
        self.sendpickle({'cmd':'write',
                       'stream':name,
                       'data':data
                       })

    def input(self, prompt=''):
        self.sendpickle({'cmd':'input',
                         'stream':'stdin',
                         'data':prompt})
        result = self.receivemsg()
        return result['data']

    # internal
    def sendpickle(self, data):
        data = json.dumps(data) + "\n\r"
        self.capacity -= len(data)
        if self.capacity < 0:
            data = json.dumps({'cmd':'stop',
                                 'timedout':True}, 2)
            orig_stdout.write(data)
            raise SystemExit
        orig_stdout.write(data)

    def receivepickle(self):
        msg = json.loads(orig_stdin.readline())
        if msg['cmd'] == 'canvasevent':
            self.canvas.append(msg)
        else:
            self.messages.append(msg)

    def receivemsg(self):
        while not self.messages:
            self.receivepickle()
        return self.messages.pop()

    def receivecanvas(self):
        while not self.canvas:
            self.receivepickle()
        return self.canvas.pop(0)

# Hide 0/1 from sys
shell = Shell()
sys.__stdin__ = sys.stdin = PseudoInputFile(shell, 'stdin')
sys.__stdout__ = sys.stdout = PseudoOutputFile(shell, 'stdout')
#sys.__stderr__ = sys.stderr = PseudoOutputFile(shell, 'stderr')
builtins.input = shell.input

#iothread = threading.Thread(target=shell.run)
#iothread.start()

if __name__ == '__main__':
    parser = ArgumentParser(description='A python interpreter that generates json commands based on the standard I/O streams.')
    parser.add_argument('-f', '--filename', type=str, required=True, default='exercise.py', help='Python file to be interpreted.')
    args = parser.parse_args()

    filepath = os.path.join("/", "workspace", args.filename)
    with open(filepath, "r", encoding='utf-8') as f:
        script = f.read()
    c = compile(script, args.filename, 'exec')
    exec(c, {})

    # work-around for docker not terminating properly
    shell.sendpickle({'cmd':'exit'})
