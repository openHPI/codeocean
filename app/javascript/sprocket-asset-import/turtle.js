// These variables are polluting the global namespace, but there's currently no alternative.
// Otherwise, the turtle won't work (click events won't be registered properly) or
// running the turtle again after a timeout yields a too large canvas (when devicePixelRatio is > 1).
var height;
var width;

export default function Turtle(canvas) {
    var dx, dy, xpos, ypos;
    this.canvas = canvas; // jQuery object

    this.items = [];
    this.canvas.off('click');

    let sendEvent = function (x, y) {
        CodeOceanEditorWebsocket.websocket.send(JSON.stringify({
            'cmd': 'canvasevent',
            'type': '<Button-1>',
            'x': x,
            'y': y
        }));
        CodeOceanEditorWebsocket.websocket.send('\n');
    };

    this.handleArrowKeys = function(e) {
        if (!CodeOceanEditorWebsocket.websocket ||
            CodeOceanEditorWebsocket.websocket.getReadyState() !== WebSocket.OPEN) {
            return;
        }

        switch(e.which) {
            case 37: // left
                sendEvent(140, 160);
                break;

            case 38: // up
                sendEvent(160, 140);
                break;

            case 39: // right
                sendEvent(180, 160);
                break;

            case 40: // down
                sendEvent(160, 180);
                break;

            default: return; // exit this handler for other keys
        }
        e.preventDefault(); // prevent the default action (scroll / move caret)
    }

    $(document).keydown(this.handleArrowKeys);

    this.canvas.click(function (e) {
        if (e.eventPhase !== 2) {
            return;
        }
        e.stopPropagation();
        dx = this.canvas[0].width / (2 * this.get_devicePixelRatio());
        dy = this.canvas[0].height / (2 * this.get_devicePixelRatio());
        if(e.offsetX===undefined)
        {
            var offset = canvas.offset();
            xpos = e.pageX-offset.left;
            ypos = e.pageY-offset.top;
        }
        else
        {
            xpos = e.offsetX;
            ypos = e.offsetY;
        }
        sendEvent(xpos - dx, ypos - dy);
    }.bind(this));
}

Turtle.prototype.update = function () {
    let k, c;
    const canvas = this.canvas[0];
    if (canvas === undefined) {
        return;
    }
    canvas.width = this.get_width() * this.get_devicePixelRatio();
    canvas.height = this.get_height() * this.get_devicePixelRatio();
    canvas.style.width = `${this.get_width()}px`;
    canvas.style.height = `${this.get_height()}px`;
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, this.get_width(), this.get_height());
    ctx.scale(this.get_devicePixelRatio(), this.get_devicePixelRatio());
    const dx = canvas.width / (2 * this.get_devicePixelRatio());
    const dy = canvas.height / (2 * this.get_devicePixelRatio());
    for (let item of this.items) {
        // This should not happen, but it does for some unknown reason.
        // Therefore, we just check for the potential error and break.
        if (item === undefined || item === null) {
            break;
        }

        c = item.coords;
        switch (item.type) {
        case 'line':
            ctx.beginPath();
            ctx.moveTo(c[0] + dx, c[1] + dy);
            for (k = 2; k < c.length; k += 2) {
                ctx.lineTo(c[k] + dx, c[k + 1] + dy);
            }
            if (item.fill) {
                ctx.strokeStyle = item.fill;
            }
            if (item.width) {
                ctx.lineWidth = item.width;
            }

            ctx.stroke();
            break;
        case 'polygon':
            ctx.beginPath();
            ctx.moveTo(c[0] + dx, c[1] + dy);
            for (k = 2; k < c.length; k += 2) {
                ctx.lineTo(c[k] + dx, c[k + 1] + dy);
            }
            ctx.closePath();
            if (item.fill !== "") {
                ctx.fillStyle = item.fill;
                ctx.strokeStyle = item.fill;
                ctx.fill();
            }
            if (item.width) {
                ctx.lineWidth = item.width;
            }
            ctx.stroke();
            break;
        case 'image':
            break;
        }
    }
};

Turtle.prototype.get_width = function () {
    if (width === undefined) {
        if (this.canvas === undefined || this.canvas[0] === undefined) {
            return;
        }
        width = this.canvas[0].width;
    }
    return width;
};

Turtle.prototype.get_height = function () {
    if (height === undefined) {
        if (this.canvas === undefined || this.canvas[0] === undefined) {
            return;
        }
        height = this.canvas[0].height;
    }
    return height;
};

Turtle.prototype.get_devicePixelRatio = function () {
    return window.devicePixelRatio || 1;
}

Turtle.prototype.delete = function (item) {
    if (item === 'all') {
        this.items = [];
    } else {
        delete this.items[item];
    }
};

Turtle.prototype.create_image = function (image) {
    this.items.push({type:'image',image:image});
    return this.items.length - 1;
};

Turtle.prototype.create_line = function () {
    this.items.push({type:'line',
                     fill: '',
                     coords:[0,0,0,0],
                     width:2,
                     capstyle:'round'});
    return this.items.length - 1;
};

Turtle.prototype.create_polygon = function () {
    this.items.push({type:'polygon',
                     // fill: "" XXX
                     // outline: "" XXX
                     coords:[0,0,0,0,0,0]
                    });
    return this.items.length - 1;
};

// XXX might make this varargs as in Tkinter
Turtle.prototype.coords = function (item, coords) {
    if (this.items[item] === undefined) {
        return;
    } else if (coords === undefined) {
        return this.items[item].coords;
    } else {
        this.items[item].coords = coords;
    }
};

Turtle.prototype.itemconfigure = function (item, key, value) {
    const element = this.items[item];
    if (element !== undefined) {
        element[key] = value;
    }
};

// value might be undefined
Turtle.prototype.css = function (key, value) {
    if (value === undefined) {
        return this.canvas.css(key);
    } else {
        // jQuery return value is confusing when the css is set
        this.canvas.css(key, value);
    }
};
