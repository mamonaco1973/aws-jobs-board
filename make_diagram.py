#!/usr/bin/env python3
"""Generate the README architecture diagram, one SVG per colour scheme.

Two files rather than one self-switching file: GitHub strips <style> blocks
from inline SVG, so a `prefers-color-scheme` media query inside the document is
silently dropped. The README pairs them with <picture>, which GitHub honours.

A README diagram is studied, not narrated, so it is COMPLETE rather than
minimal: the public load balancer, the single Fargate task with its image
and secrets, the NAT gateway it reaches the internet through, and the
PostgreSQL, Redis and S3 stores are all on it.
Run:  python3 make_diagram.py
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))

# ------------------------------------------------------------------------------
# Geometry and style (shared with the other projects' diagrams)
# ------------------------------------------------------------------------------
NW, NH = 420, 110                          # node width, height
GUTTER = 140                               # between columns: room for a label
MARGIN = 40
COL = [MARGIN + i * (NW + GUTTER) for i in range(3)]
ROW = [40 + i * 200 for i in range(4)]
W = MARGIN * 2 + NW * 3 + GUTTER * 2
H = ROW[-1] + NH + 40 + 0
TITLE_PX, SUB_PX, EDGE_PX = 26, 17, 16

THEMES = {
    "dark": {
        "bg": "#0d1117", "panel": "#161b22", "text": "#e6edf3",
        "muted": "#8b949e", "line": "#58a6ff", "local": "#39c5bb",
        "purple": "#c39be8", "navy": "#c8d6e8", "blue": "#58a6ff",
        "amber": "#f2c163", "store": "#7ee787",
    },
    "light": {
        "bg": "#ffffff", "panel": "#f6f8fa", "text": "#1f2328",
        "muted": "#59636e", "line": "#0969da", "local": "#137e77",
        "purple": "#8250df", "navy": "#475467", "blue": "#0969da",
        "amber": "#9a6700", "store": "#1a7f37",
    },
}

# Lucide icon paths, on a 24-unit grid.
ICONS = {
    "globe": ['<circle cx="12" cy="12" r="10"/>',
              '<path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/>',
              '<path d="M2 12h20"/>'],
    "route": ['<circle cx="6" cy="19" r="3"/>', '<circle cx="18" cy="5" r="3"/>',
              '<path d="M12 19h4.5a3.5 3.5 0 0 0 0-7h-8a3.5 3.5 0 0 1 0-7H12"/>'],
    "network": ['<rect x="16" y="16" width="6" height="6" rx="1"/>',
                '<rect x="2" y="16" width="6" height="6" rx="1"/>',
                '<rect x="9" y="2" width="6" height="6" rx="1"/>',
                '<path d="M5 16v-3a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v3"/>',
                '<path d="M12 12V8"/>'],
    "layers": ['<path d="m12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83'
               'l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z"/>',
               '<path d="m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65"/>',
               '<path d="m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65"/>'],
    "database": ['<ellipse cx="12" cy="5" rx="9" ry="3"/>',
                 '<path d="M3 5V19A9 3 0 0 0 21 19V5"/>',
                 '<path d="M3 12A9 3 0 0 0 21 12"/>'],
    "key": ['<path d="M2.586 17.414A2 2 0 0 0 2 18.828V21a1 1 0 0 0 1 1h3a1 1 0 0 0 '
            '1-1v-1a1 1 0 0 1 1-1h1a1 1 0 0 0 1-1v-1a1 1 0 0 1 1-1h.172a2 2 0 0 0 '
            '1.414-.586l.814-.814a6.5 6.5 0 1 0-4-4z"/>',
            '<circle cx="16.5" cy="7.5" r=".5"/>'],
    "monitor": ['<rect width="20" height="14" x="2" y="3" rx="2"/>',
                '<line x1="8" x2="16" y1="21" y2="21"/>',
                '<line x1="12" x2="12" y1="17" y2="21"/>'],
    "terminal": ['<polyline points="4 17 10 11 4 5"/>',
                 '<line x1="12" x2="20" y1="19" y2="19"/>'],
    "users": ['<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>',
              '<circle cx="9" cy="7" r="4"/>',
              '<path d="M22 21v-2a4 4 0 0 0-3-3.87"/>',
              '<path d="M16 3.13a4 4 0 0 1 0 7.75"/>'],
    "file": ['<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/>',
             '<path d="M14 2v4a2 2 0 0 0 2 2h4"/>', '<path d="M10 9H8"/>',
             '<path d="M16 13H8"/>', '<path d="M16 17H8"/>'],
}

NODES = {}


def _r(nid):
    """Return (left, top, right, bottom, centre-x, centre-y) for a node."""
    x, y = NODES[nid][0], NODES[nid][1]
    return x, y, x + NW, y + NH, x + NW / 2, y + NH / 2


def gutter_x(c):
    """Centre of the gutter to the right of column c."""
    return COL[c] + NW + GUTTER / 2


def gutter_y(r):
    """Centre of the gap below row r."""
    return ROW[r] + NH + (ROW[1] - ROW[0] - NH) / 2


# ------------------------------------------------------------------------------
# Layout
# ------------------------------------------------------------------------------
# The browser is at the top between Route 53 (left) and the ACM certificate
# (right). Requests go straight down through the load balancer to the Fargate
# task; its image and secrets come from the left, its outbound traffic leaves
# through the NAT gateway on the right to Bedrock, and its three stores sit
# along the bottom.
#
# id: (x, y, colour key, icon, title, subtitle[, "dashed"])
NODES.update({
    "browser":  (COL[1], ROW[0], "navy", "globe", "Browser",
                 "candidates and employers"),
    "ecr":      (COL[0], ROW[1], "navy", "file", "jobboard (ECR)",
                 "image tagged :latest"),
    "alb":      (COL[1], ROW[1], "amber", "route", "Application Load Balancer",
                 "public subnets, HTTP 80"),
    "secrets":  (COL[0], ROW[2], "purple", "key", "Secrets Manager",
                 "3 jobboard_* secrets"),
    "ecs":      (COL[1], ROW[2], "blue", "terminal", "ECS Fargate task",
                 "Rails: Puma + Sidekiq, 0.5 vCPU / 1 GB"),
    "nat":      (COL[2], ROW[2], "navy", "network", "NAT gateway",
                 "private subnet egress"),
    "rds":      (COL[0], ROW[3], "store", "database", "RDS PostgreSQL 16",
                 "db.t3.micro, private"),
    "redis":    (COL[1], ROW[3], "store", "database", "ElastiCache Redis",
                 "cache.t3.micro, Sidekiq queue"),
    "s3":       (COL[2], ROW[3], "store", "layers", "jobboard-uploads",
                 "S3 ActiveStorage: resumes"),
})

br, ecr = _r("browser"), _r("ecr")
alb, sec, ecs = _r("alb"), _r("secrets"), _r("ecs")
nat, rds, rd, s3 = _r("nat"), _r("rds"), _r("redis"), _r("s3")

# id: (path, colour key, label, label_x, label_y, anchor[, "dashed"])
EDGES = {
    "e_https":  (f"M{br[4]},{br[3]} V{alb[1] - 5}", "line",
                 "HTTP", br[4] + 14, gutter_y(0) + 6, "start"),
    "e_app":    (f"M{alb[4]},{alb[3]} V{ecs[1] - 5}", "line",
                 "port 3000", alb[4] + 14, gutter_y(1) + 6, "start"),
    "e_img":    (f"M{ecr[4]},{ecr[3]} V{gutter_y(1)} H{ecs[4] - 120} V{ecs[1] - 5}",
                 "navy", "image", ecr[4] + 14, gutter_y(1) - 10, "start"),
    "e_sec":    (f"M{sec[2]},{sec[5]} H{ecs[0] - 5}", "purple",
                 "env at start", gutter_x(0), sec[5] - 12, "middle"),
    "e_nat":    (f"M{ecs[2]},{ecs[5]} H{nat[0] - 5}", "line",
                 "egress", gutter_x(1), ecs[5] - 12, "middle"),
    "e_rds":    (f"M{ecs[4] - 120},{ecs[3]} V{gutter_y(2)} H{rds[4]} V{rds[1] - 5}",
                 "store", "5432", rds[4] + 14, gutter_y(2) - 10, "start"),
    "e_redis":  (f"M{ecs[4]},{ecs[3]} V{rd[1] - 5}", "store",
                 "6379", ecs[4] + 14, gutter_y(2) + 20, "start"),
    "e_s3":     (f"M{ecs[4] + 120},{ecs[3]} V{gutter_y(2)} H{s3[4]} V{s3[1] - 5}",
                 "store", "ActiveStorage", s3[4] + 14, gutter_y(2) - 10,
                 "start"),
}

ALT = ("Candidates and employers reach an Application Load Balancer in the "
       "public subnets on HTTP port 80, which forwards to one ECS Fargate task "
       "on port 3000 in the private subnets, running the Rails job board under "
       "Puma with Sidekiq alongside. The task pulls its image from ECR, gets "
       "three settings from Secrets Manager at start, stores data in RDS "
       "PostgreSQL, queues notification jobs in ElastiCache Redis, keeps "
       "uploaded resumes in S3 through ActiveStorage, and reaches the internet "
       "through the NAT gateway.")

# ------------------------------------------------------------------------------
# Rendering
# ------------------------------------------------------------------------------
from html import escape

FONT = "-apple-system, BlinkMacSystemFont, Segoe UI, Helvetica, Arial, sans-serif"


def node_svg(nid, t):
    """Render one service box: rounded panel, icon, title, subtitle."""
    x, y, key, icon, title, sub, *opt = NODES[nid]
    title, sub = escape(title), escape(sub)
    colour = t[key]
    dash = ' stroke-dasharray="10 7"' if opt and opt[0] == "dashed" else ""
    scale = 1.25
    isz = 24 * scale
    ix, iy = x + 20, y + (NH - isz) / 2
    tx = x + 20 + isz + 14
    return "".join([
        f'<rect x="{x}" y="{y}" width="{NW}" height="{NH}" rx="10" ry="10" '
        f'fill="{t["panel"]}" stroke="{colour}" stroke-width="2"{dash}/>',
        f'<g transform="translate({ix},{iy}) scale({scale})" fill="none" '
        f'stroke="{colour}" stroke-width="2" stroke-linecap="round" '
        f'stroke-linejoin="round">' + "".join(ICONS[icon]) + "</g>",
        f'<text x="{tx}" y="{y + NH/2 - 4}" font-family="{FONT}" '
        f'font-size="{TITLE_PX}" font-weight="600" fill="{t["text"]}">{title}</text>',
        f'<text x="{tx}" y="{y + NH/2 + 22}" font-family="{FONT}" '
        f'font-size="{SUB_PX}" fill="{t["muted"]}">{sub}</text>',
    ])


def edge_svg(eid, t):
    """Render one arrow plus its label (on a background chip, so lines that
    pass behind a label never cut through its text)."""
    d, key, label, lx, ly, anchor, *opt = EDGES[eid]
    label = escape(label)
    colour = t[key]
    dash = ' stroke-dasharray="8 6"' if opt and opt[0] == "dashed" else ""
    out = (f'<path d="{d}" fill="none" stroke="{colour}" stroke-width="2"{dash} '
           f'marker-end="url(#a_{eid})"/>')
    if label:
        out += (f'<text x="{lx}" y="{ly}" text-anchor="{anchor}" '
                f'font-family="{FONT}" font-size="{EDGE_PX}" font-weight="600" '
                f'fill="{colour}" stroke="{t["bg"]}" stroke-width="6" '
                f'paint-order="stroke">{label}</text>')
    return out


def build(t):
    """Assemble the diagram for one theme."""
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
           f'viewBox="0 0 {W} {H}" role="img" aria-label="{ALT}">', "<defs>"]
    # One marker per edge: a shared marker cannot carry per-edge colour.
    for eid, spec in EDGES.items():
        out.append(
            f'<marker id="a_{eid}" viewBox="0 0 10 10" refX="9" refY="5" '
            f'markerWidth="5" markerHeight="5" orient="auto-start-reverse">'
            f'<path d="M0,0 L10,5 L0,10 z" fill="{t[spec[1]]}"/></marker>')
    out.append("</defs>")
    out.append(f'<rect width="{W}" height="{H}" fill="{t["bg"]}"/>')
    for eid in EDGES:
        out.append(edge_svg(eid, t))
    for nid in NODES:
        out.append(node_svg(nid, t))
    out.append("</svg>")
    return "".join(out)


def main():
    for name, theme in THEMES.items():
        path = os.path.join(HERE, f"architecture-{name}.svg")
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(build(theme))
        print(f"  architecture-{name}.svg")


if __name__ == "__main__":
    main()
