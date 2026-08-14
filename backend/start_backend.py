import subprocess
import sys

print("Starting backend and capturing output to backend_crash.log...")
with open("backend_crash.log", "w") as log_file:
    process = subprocess.Popen(
        [sys.executable, "app.py"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )
    for line in process.stdout:
        print(line, end="")
        log_file.write(line)
        log_file.flush()

print(f"Backend exited with code {process.wait()}")
