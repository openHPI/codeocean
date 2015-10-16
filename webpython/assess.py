import webpython, contextlib, io, json, sys, turtle, ast
from webpython import shell

turtle_operations = []
bindings = {}

class RecordingPen:
    _pen = None
    _screen = None
    def __init__(self):
        self.operations = turtle_operations
        self._pos = (0,0)
        turtle_operations.append(('__init__',()))

    def reset(self):
        turtle_operations.clear()

    def onclick(self, fun, btn=1, add=None):
        self.operations.append(('onclick', (fun,)))
        def eventfun(event):
            fun(event.x, event.y)
        bindings['<Button-1>'] = eventfun

    def goto(self, x, y):
        self._pos = (x,y)
        self.operations.append(('goto', (x,y)))

    def pos(self):
        self.operations.append(('pos', ()))
        return self._pos

    def __getattr__(self, method):
        def func(*args):
            self.operations.append((method, args))
        return func

class FakeCanvas(turtle.WebCanvas):
    def flushbatch(self):
        pass

    def get_width(self):
        return 400

    def get_height(self):
        return 400

    def delete(self, item):
        pass

    def css(self, key, value):
        pass

fake_events = []
def mainloop():
    while fake_events:
        e = turtle.Event(fake_events.pop(0))
        if e.type in bindings:
            bindings[e.type](e)

turtle.Turtle = RecordingPen
turtle.WebCanvas = FakeCanvas
pen = turtle._getpen()
turtle.mainloop = mainloop

def filter_operations(name):
    return [o for o in turtle_operations if o[0] == name]

@contextlib.contextmanager
def capture():
    global captured_out
    import sys
    oldout,olderr = sys.stdout, sys.stderr
    try:
        out=[io.StringIO(), io.StringIO()]
        captured_out = out
        sys.stdout,sys.stderr = out
        yield out
    finally:
        sys.stdout,sys.stderr = oldout, olderr
        out[0] = out[0].getvalue()
        out[1] = out[1].getvalue()

def get_source():
    message = json.loads(sys.argv[1])
    return message['data']

def get_ast():
    s = get_source()
    return ast.parse(s, "programm.py", "exec")

def has_bare_except():
    for node in ast.walk(get_ast()):
        if isinstance(node, ast.ExceptHandler):
            if node.type is None:
                return True
    return False

def runcaptured(prefix='', tracing=None, variables=None, source=''):
    #message = json.loads(sys.argv[1])
    #source = prefix + message['data']
    with open("programm.py", "w", encoding='utf-8') as f:
        f.write(source)
    c = compile(source, "programm.py", 'exec')
    with capture() as out, trace(tracing):
        if variables is None:
            variables = {}
        exec(c, variables)
    return source, out[0], out[1], variables

def runfunc(func, *args, tracing=None):
    with capture() as out, trace(tracing):
        res = func(*args)
    return out[0], out[1], res

def passed():
    msg_in = json.loads(sys.argv[1])
    msg_out = {'cmd':'passed'}
    msg_out['lis_outcome_service_url'] = msg_in['lis_outcome_service_url']
    msg_out['lis_result_sourcedid'] = msg_in['lis_result_sourcedid']
    webpython.shell.sendpickle(msg_out)

def failed(msg):
    msg_in = json.loads(sys.argv[1])
    msg_out = {'cmd':'failed', 'data':'Dein Programm ist leider falsch:\n'+msg}
    msg_out['lis_outcome_service_url'] = msg_in['lis_outcome_service_url']
    msg_out['lis_result_sourcedid'] = msg_in['lis_result_sourcedid']
    webpython.shell.sendpickle(msg_out)

def modified(variables, name, val):
    if variables.get(name) != val:
        msg_in = json.loads(sys.argv[1])
        msg_out = {'cmd':'failed',
                   'data':('Bitte lösche Deine Zuweisung der Variable %s, '+
                   'damit wir Dein Programm überprüfen können.') % name}
        msg_out['lis_outcome_service_url'] = msg_in['lis_outcome_service_url']
        msg_out['lis_result_sourcedid'] = msg_in['lis_result_sourcedid']
        webpython.shell.sendpickle(msg_out)
        return True
    return False

undefined = object()
def getvar(variables, name):
    try:
        return variables['name']
    except KeyError:
        name = name.lower()
        for k,v in variables.items():
            if k.lower() == name:
                return v
        return undefined

def _match(n1, n2):
    if n1 == n2:
        return True
    if n1 is None or n2 is None:
        return False
    return n1.lower() == n2.lower()

class Call:
    def __init__(self, name, args):
        self.name = name
        self.args = args
        self.calls = []
        self.current = None

    def findcall(self, f):
        if _match(self.name, f):
            return self
        for c in self.calls:
            r = c.findcall(f)
            if r:
                return r
        return None

    def calling(self, caller, callee):
        if _match(self.name, caller):
            for c in self.calls:
                if _match(c.name, callee):
                    return True
        for c in self.calls:
            if c.calling(caller, callee):
                return True
        return False

    def countcalls(self, caller, callee):
        calls = 0
        if _match(self.name, caller):
            for c in self.calls:
                if _match(c.name, callee):
                    calls += 1
            return calls
        for c in self.calls:
            r = c.countcalls(caller, callee)
            if r > 0:
                return r
        return 0

class Tracing(Call):
    def __init__(self):
        Call.__init__(self, None, None)

    def trace(self, frame, event, arg):
        if event == 'call':
            c = Call(frame.f_code.co_name, frame.f_locals.copy())
            cur = self
            while cur.current:
                cur = cur.current
            cur.calls.append(c)
            cur.current = c
            return self.trace
        elif event in ('return', 'exception'):
            cur = self
            if not cur.current:
                # XXX return without call? happens when invocation of top function fails
                return
            while cur.current.current:
                cur = cur.current
            cur.current = None

    def start(self):
        sys.settrace(self.trace)

    def stop(self):
        sys.settrace(None)

@contextlib.contextmanager
def trace(t):
    try:
        if t:
            t.start()
        yield
    finally:
        if t:
            t.stop()
