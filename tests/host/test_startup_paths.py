"""Long sandbox paths, synthetic bytes, no ROM/game execution."""
import pathlib
import subprocess
import sys
import tempfile
with tempfile.TemporaryDirectory(prefix="port-startup-") as root:
    path = pathlib.Path(root)
    for _ in range(7):
        path /= "sandbox-" + "x" * 100
    path.mkdir(parents=True)
    assert len(str(path)) > 768
    subprocess.run([sys.argv[1], str(path)], check=True)
