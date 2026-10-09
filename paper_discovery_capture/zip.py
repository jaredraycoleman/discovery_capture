"""Build a submission archive.

    python zip.py                # arxiv-submission.zip (minimal, for arXiv)
    python zip.py camera-ready   # camera-ready.zip (all sources, for Springer)

Both include main.tex (with comments stripped, since arXiv publishes the
source and Springer redistributes it), main.bbl (arXiv does not run BibTeX),
llncs.cls, and every figure the paper references via \\includegraphics. The
camera-ready archive additionally includes refs.bib and splncs04.bst so
Springer can re-typeset the bibliography. Run after a full pdflatex/bibtex
build so main.bbl is up to date.
"""

import pathlib
import re
import sys
import zipfile

thisdir = pathlib.Path(__file__).resolve().parent

TEX_FILES = ["main.tex"]
EXTRA_FILES = ["main.bbl", "llncs.cls"]
CAMERA_READY_EXTRA_FILES = ["refs.bib", "splncs04.bst"]


def strip_comments(text: str) -> str:
    """Remove LaTeX comments while preserving compile behavior.

    Lines that are entirely comments are dropped. For inline comments, the
    text after `%` is removed but the `%` itself is kept so end-of-line
    spacing is unchanged. Escaped `\\%` is not treated as a comment.
    """
    out_lines = []
    for line in text.splitlines():
        comment_at = None
        i = 0
        while i < len(line):
            if line[i] == "\\":
                i += 2  # skip escaped character (handles \% and \\)
                continue
            if line[i] == "%":
                comment_at = i
                break
            i += 1
        if comment_at is None:
            out_lines.append(line)
        elif line[:comment_at].strip() == "":
            continue  # whole-line comment: drop the line
        else:
            out_lines.append(line[: comment_at + 1])
    return "\n".join(out_lines) + "\n"


def referenced_figures(tex: str) -> list[str]:
    """Figure paths used by \\includegraphics in (comment-stripped) tex."""
    return re.findall(r"\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}", tex)


def main():
    camera_ready = len(sys.argv) > 1 and sys.argv[1] == "camera-ready"
    output = "camera-ready.zip" if camera_ready else "arxiv-submission.zip"
    extra_files = EXTRA_FILES + (CAMERA_READY_EXTRA_FILES if camera_ready else [])

    path = thisdir.joinpath(output)
    path.unlink(missing_ok=True)

    bbl = thisdir.joinpath("main.bbl")
    if not bbl.exists():
        sys.exit("main.bbl not found: run pdflatex + bibtex first")
    if bbl.stat().st_mtime < thisdir.joinpath("main.tex").stat().st_mtime:
        print("warning: main.bbl is older than main.tex; rebuild before submitting")

    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as zf:
        figures = []
        for name in TEX_FILES:
            stripped = strip_comments(thisdir.joinpath(name).read_text())
            zf.writestr(name, stripped)
            figures += referenced_figures(stripped)

        for name in extra_files:
            zf.write(thisdir.joinpath(name), name)

        for figure in figures:
            zf.write(thisdir.joinpath(figure), figure)

        print(f"{output}:")
        for info in zf.infolist():
            print(f"  {info.filename}")


if __name__ == "__main__":
    main()
