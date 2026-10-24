#!/usr/bin/env python3
"""Generate the Graphite icon theme: the spec's line-drawn folder, file and place glyphs
as scalable SVGs, inheriting everything else (apps, actions, emblems) from Papirus-Dark."""
import os, sys, json

OUT = os.path.expanduser("~/.local/share/icons/Graphite")

# Colours follow the active Caelestia scheme (re-run from the cli.json postHook on every change);
# the graphite constants are the fallback when no scheme file exists.
def _scheme():
    try:
        with open(os.path.expanduser("~/.local/state/caelestia/scheme.json")) as f:
            return json.load(f)["colours"]
    except Exception:
        return {}
_C = _scheme()
def _hex(key, default):
    v = _C.get(key)
    return f"#{v}" if v else default
def _rgb(h):
    return ",".join(str(int(h[i:i+2], 16)) for i in (1, 3, 5))

ACC = _hex("secondary", "#8e8e98")          # folder strokes, label text (spec --vio)
ACC_RGB = _rgb(ACC)
BODY = _hex("surfaceContainerLow", "#131316")  # file body fill
LINE = _hex("outlineVariant", "#4a4a54")     # file outline
FONT = "JetBrainsMono NF, JetBrainsMono Nerd Font, JetBrains Mono, monospace"

# 24-grid line glyphs, verbatim from the spec's core.js
G = {
    "folder":   '<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
    "file":     '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/>',
    "image":    '<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="9" cy="9" r="1.5"/><path d="M21 15l-5-5L5 21"/>',
    "music":    '<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>',
    "code":     '<path d="M16 18l6-6-6-6M8 6l-6 6 6 6"/>',
    "home":     '<path d="M3 11l9-8 9 8M5 10v10h14V10"/>',
    "download": '<path d="M12 3v12M7 10l5 5 5-5M5 21h14"/>',
    "trash":    '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
    "terminal": '<path d="M4 17l6-5-6-5M12 19h8"/>',
    "globe":    '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>',
    "hdd":      '<path d="M3 14h18v6H3z"/><path d="M3 14l3-9h12l3 9M7 17h.01"/>',
    "archive":  '<rect x="3" y="4" width="18" height="5" rx="1"/><path d="M5 9v10h14V9M10 13h4"/>',
    "play":     '<path d="M7 4l13 8-13 8z" fill="currentColor"/>',
    "clock":    '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 3"/>',
    "desktop":  '<rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8M12 16v4"/>',
    "star":     '<path d="M12 3l2.8 5.7 6.2.9-4.5 4.4 1.1 6.2L12 17.3 6.4 20.2l1.1-6.2L3 9.6l6.2-.9z"/>',
    "link":     '<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1"/><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>',
}

def svg(body, vb="0 0 64 64"):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" width="64" height="64">{body}</svg>\n'

def glyph(name, colour=ACC, stroke=1.5, extra=""):
    """A spec line glyph on the 24 grid, scaled to fill the 64 canvas with 8-unit padding."""
    return svg(f'<g transform="translate(8 8) scale(2)" fill="none" stroke="{colour}" stroke-width="{stroke}" '
               f'stroke-linecap="round" stroke-linejoin="round">{G[name]}{extra}</g>')

def folder(inner=None, open_=False):
    """The spec's big folder (56x46), with an optional small glyph centred inside."""
    fill = f"rgba({ACC_RGB},{'.18' if open_ else '.10'})"
    body = (f'<g transform="translate(4 9)"><path d="M2 7a2 2 0 0 1 2-2h14l5 5h29a2 2 0 0 1 2 2v27a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2z" '
            f'fill="{fill}" stroke="{ACC}" stroke-width="1.4"/><path d="M2 15h52" stroke="{ACC}" stroke-opacity=".45" stroke-width="1.4"/>')
    if inner:
        # 24-grid glyph at 18 units, centred in the folder body below the tab line
        body += (f'<g transform="translate(19 20) scale(.75)" fill="none" stroke="{ACC}" stroke-opacity=".9" stroke-width="1.6" '
                 f'stroke-linecap="round" stroke-linejoin="round">{G[inner]}</g>')
    body += '</g>'
    return svg(body)

def doc(label):
    """The spec's file glyph (44x56) with an uppercase extension label."""
    size = 9.5 if len(label) <= 3 else (8 if len(label) == 4 else 6.8)
    return svg(f'<g transform="translate(10 4)"><path d="M2 2h28l12 12v40H2z" fill="{BODY}" stroke="{LINE}" stroke-width="1.4"/>'
               f'<path d="M30 2v12h12" fill="none" stroke="{LINE}" stroke-width="1.4"/>'
               f'<text x="22" y="40" text-anchor="middle" font-size="{size}" font-family="{FONT}" font-weight="500" fill="{ACC}">{label}</text></g>')

PLACES = {
    "folder": folder(), "inode-directory": folder(), "folder-open": folder(open_=True),
    "folder-drag-accept": folder(open_=True), "folder-remote": folder("globe"), "folder-saved-search": folder(),
    "folder-templates": folder("file"), "folder-publicshare": folder("globe"), "folder-documents": folder("file"),
    "folder-download": folder("download"), "folder-downloads": folder("download"), "folder-pictures": folder("image"),
    "folder-music": folder("music"), "folder-videos": folder("play"), "folder-code": folder("code"),
    "folder-projects": folder("code"), "folder-games": folder(), "folder-recent": folder("clock"),
    "user-home": glyph("home"), "user-desktop": glyph("desktop"), "user-trash": glyph("trash"),
    "user-trash-full": glyph("trash", extra='<path d="M9 11h6"/>'), "user-bookmarks": glyph("star"),
    "document-open-recent": glyph("clock"), "folder-recent-symbolic": glyph("clock"),
    "drive-harddisk": glyph("hdd"), "drive-harddisk-system": glyph("hdd"), "drive-harddisk-usb": glyph("hdd"),
    "drive-harddisk-solidstate": glyph("hdd"), "drive-removable-media": glyph("hdd"), "drive-removable-media-usb": glyph("hdd"),
    "media-removable": glyph("hdd"), "media-flash": glyph("hdd"), "drive-optical": glyph("hdd"), "computer": glyph("hdd"),
    "network-workgroup": glyph("globe"), "network-server": glyph("globe"), "network-wired": glyph("globe"), "folder-network": folder("globe"),
    "inode-symlink": glyph("link"),
}

MIMES = {
    "text-x-generic": "TXT", "text-plain": "TXT", "text-x-log": "LOG", "text-x-readme": "TXT", "text-markdown": "MD",
    "text-x-markdown": "MD", "text-x-script": "SH", "text-x-shellscript": "SH", "application-x-shellscript": "SH",
    "text-x-python": "PY", "text-x-python3": "PY", "text-x-lua": "LUA", "text-x-c": "C", "text-x-csrc": "C", "text-x-chdr": "H",
    "text-x-c++": "CPP", "text-x-c++src": "CPP", "text-x-c++hdr": "HPP", "text-x-java": "JAVA", "text-x-rust": "RS", "text-x-go": "GO",
    "text-javascript": "JS", "application-javascript": "JS", "application-x-javascript": "JS", "text-x-typescript": "TS",
    "text-html": "HTML", "text-css": "CSS", "text-csv": "CSV", "text-x-tex": "TEX", "text-x-patch": "DIFF", "text-x-diff": "DIFF",
    "text-x-makefile": "MK", "text-x-qml": "QML", "text-x-nix": "NIX", "text-x-haskell": "HS", "text-x-ruby": "RB", "text-x-perl": "PL",
    "text-x-php": "PHP", "text-x-sql": "SQL", "text-x-cmake": "CMAKE", "text-x-meson": "MESON", "application-x-php": "PHP",
    "application-json": "JSON", "application-xml": "XML", "text-xml": "XML", "application-x-yaml": "YAML", "text-x-yaml": "YAML",
    "application-yaml": "YAML", "application-toml": "TOML", "text-x-ini": "INI", "application-x-ini": "INI",
    "application-pdf": "PDF", "application-x-cd-image": "ISO", "application-x-iso9660-image": "ISO", "application-x-raw-disk-image": "IMG",
    "application-x-qemu-disk": "QCOW", "application-zstd": "ZST", "application-x-zstd-compressed-tar": "TZST", "application-zip": "ZIP",
    "application-x-tar": "TAR", "application-gzip": "GZ", "application-x-gzip": "GZ", "application-x-compressed-tar": "TGZ",
    "application-x-xz": "XZ", "application-x-xz-compressed-tar": "TXZ", "application-x-bzip": "BZ2", "application-x-bzip2": "BZ2",
    "application-x-bzip-compressed-tar": "TBZ", "application-x-7z-compressed": "7Z", "application-x-rar": "RAR", "application-vnd.rar": "RAR",
    "package-x-generic": "PKG", "application-x-archive": "AR", "application-x-java-archive": "JAR",
    "application-vnd.debian.binary-package": "DEB", "application-x-rpm": "RPM", "application-vnd.flatpak": "FLAT", "application-vnd.appimage": "APP",
    "application-x-executable": "BIN", "application-x-sharedlib": "SO", "application-octet-stream": "BIN", "application-x-generic": "BIN",
    "application-x-object": "OBJ", "application-x-ms-dos-executable": "EXE", "application-vnd.microsoft.portable-executable": "EXE",
    "application-x-desktop": "APP", "application-x-zerosize": "0", "application-x-bittorrent": "TOR", "application-x-sqlite3": "DB",
    "application-vnd.sqlite3": "DB", "application-x-ipynb+json": "IPYNB", "application-x-font-ttf": "TTF", "font-x-generic": "FONT",
    "font-ttf": "TTF", "font-otf": "OTF", "application-font-woff": "WOFF", "font-woff": "WOFF",
    "image-x-generic": "IMG", "image-png": "PNG", "image-jpeg": "JPG", "image-svg+xml": "SVG", "image-gif": "GIF", "image-webp": "WEBP",
    "image-bmp": "BMP", "image-tiff": "TIFF", "image-x-xcf": "XCF", "image-vnd.adobe.photoshop": "PSD", "image-avif": "AVIF", "image-heif": "HEIF",
    "video-x-generic": "VID", "video-mp4": "MP4", "video-x-matroska": "MKV", "video-webm": "WEBM", "video-quicktime": "MOV", "video-x-msvideo": "AVI",
    "audio-x-generic": "AUD", "audio-mpeg": "MP3", "audio-flac": "FLAC", "audio-x-flac": "FLAC", "audio-x-wav": "WAV", "audio-ogg": "OGG",
    "audio-x-vorbis+ogg": "OGG", "audio-mp4": "M4A", "audio-x-opus+ogg": "OPUS",
    "x-office-document": "DOC", "application-msword": "DOC", "application-vnd.openxmlformats-officedocument.wordprocessingml.document": "DOCX",
    "application-vnd.oasis.opendocument.text": "ODT", "application-rtf": "RTF", "x-office-spreadsheet": "XLS", "application-vnd.ms-excel": "XLS",
    "application-vnd.openxmlformats-officedocument.spreadsheetml.sheet": "XLSX", "application-vnd.oasis.opendocument.spreadsheet": "ODS",
    "x-office-presentation": "PPT", "application-vnd.ms-powerpoint": "PPT", "application-vnd.openxmlformats-officedocument.presentationml.presentation": "PPTX",
    "application-vnd.oasis.opendocument.presentation": "ODP", "application-epub+zip": "EPUB", "application-x-mobipocket-ebook": "MOBI",
    "x-office-address-book": "VCF", "text-vcard": "VCF", "text-calendar": "ICS", "x-office-calendar": "ICS",
    "application-x-wine-extension-ini": "INI", "application-pgp-encrypted": "PGP", "application-pgp-keys": "KEY", "application-x-pem-file": "PEM",
    "application-x-x509-ca-cert": "CRT", "application-vnd.ms-fontobject": "EOT", "text-x-vcard": "VCF",
    "text-x-lilypond": "LY", "text-x-scheme": "SCM", "text-x-elisp": "EL", "text-x-emacs-lisp": "EL", "text-x-dart": "DART", "text-x-kotlin": "KT",
    "text-x-scala": "SCALA", "text-x-swift": "SWIFT", "text-x-zig": "ZIG", "text-x-ocaml": "ML", "text-x-erlang": "ERL", "text-x-r": "R",
    "text-x-julia": "JL", "text-x-matlab": "M", "text-x-fortran": "F90", "text-x-asm": "ASM", "text-x-nim": "NIM", "text-x-vala": "VALA",
    "text-x-dockerfile": "DOCK", "text-x-systemd-unit": "UNIT", "text-x-hex": "HEX", "text-x-opml+xml": "OPML", "text-x-objcsrc": "M",
    "text-x-cobol": "COB", "text-x-ada": "ADA", "text-x-pascal": "PAS", "text-x-bibtex": "BIB", "text-x-gettext-translation": "PO",
    "text-x-po": "PO", "text-x-json": "JSON", "text-x-sass": "SASS", "text-x-scss": "SCSS", "text-less": "LESS", "text-x-coffeescript": "COFFEE",
    "text-x-vhdl": "VHDL", "text-x-verilog": "V", "text-x-uri": "URL", "application-x-mswinurl": "URL", "text-x-ms-regedit": "REG",
}

# Window controls, spec set B ("sharp squares", glyph set d2): filled paths so GTK can recolour them
# as symbolic icons (GTK replaces fill="#2e3436" with the CSS color). 16-unit box, 10-unit glyph.
def thick(x1, y1, x2, y2, w=1.4):
    """Polygon points for a line segment drawn as a filled rectangle of width w."""
    import math
    dx, dy = x2 - x1, y2 - y1
    L = math.hypot(dx, dy) or 1.0
    nx, ny = -dy / L * w / 2, dx / L * w / 2
    pts = [(x1 + nx, y1 + ny), (x2 + nx, y2 + ny), (x2 - nx, y2 - ny), (x1 - nx, y1 - ny)]
    return " ".join(f"{x:.2f},{y:.2f}" for x, y in pts)

def symbolic(segments):
    body = "".join(f'<polygon points="{thick(*seg)}" fill="#2e3436"/>' for seg in segments)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><g transform="translate(3 3)">{body}</g></svg>\n'

ACTIONS = {
    "window-close-symbolic":    symbolic([(2.8, 2.8, 7.2, 7.2), (7.2, 2.8, 2.8, 7.2)]),
    "window-minimize-symbolic": symbolic([(2.5, 5, 7.5, 5)]),
    "window-maximize-symbolic": symbolic([(5, 2.5, 5, 7.5), (2.5, 5, 7.5, 5)]),
    "window-restore-symbolic":  symbolic([(2.5, 2.5, 7.5, 2.5), (7.5, 2.5, 7.5, 7.5), (7.5, 7.5, 2.5, 7.5), (2.5, 7.5, 2.5, 2.5)]),
}

def main():
    os.makedirs(f"{OUT}/scalable/actions", exist_ok=True)
    for name, body in ACTIONS.items():
        with open(f"{OUT}/scalable/actions/{name}.svg", "w") as f: f.write(body)
    os.makedirs(f"{OUT}/scalable/places", exist_ok=True)
    os.makedirs(f"{OUT}/scalable/mimetypes", exist_ok=True)
    for name, body in PLACES.items():
        with open(f"{OUT}/scalable/places/{name}.svg", "w") as f: f.write(body)
    for name, label in MIMES.items():
        with open(f"{OUT}/scalable/mimetypes/{name}.svg", "w") as f: f.write(doc(label))
    with open(f"{OUT}/index.theme", "w") as f:
        f.write("[Icon Theme]\nName=Graphite\nComment=Graphite line icons for folders, places and file types; everything else from Papirus-Dark\n"
                "Inherits=Papirus-Dark,hicolor\nDirectories=scalable/actions,scalable/places,scalable/mimetypes\n\n"
                "[scalable/actions]\nContext=Actions\nSize=16\nMinSize=8\nMaxSize=512\nType=Scalable\n\n"
                "[scalable/places]\nContext=Places\nSize=64\nMinSize=8\nMaxSize=512\nType=Scalable\n\n"
                "[scalable/mimetypes]\nContext=MimeTypes\nSize=64\nMinSize=8\nMaxSize=512\nType=Scalable\n")
    print(json.dumps({"actions": len(ACTIONS), "places": len(PLACES), "mimetypes": len(MIMES), "out": OUT}))

if __name__ == "__main__":
    main()
