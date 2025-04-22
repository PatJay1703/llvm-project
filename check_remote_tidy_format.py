import subprocess
import sys
import requests
import yaml
import os

# === Load config.yaml ===
with open("config.yaml", "r") as f:
    config = yaml.safe_load(f)

# === Configuration ===
PR_NUMBER = str(config["project"]["pr_number"])
OWNER = config["project"]["owner"]
REPO = config["project"]["repo"]

# Set paths for clang-tidy and the compilation database
CLANG_TIDY_PATH = "/new/llvm-project/clang/tools/clang-tidy/clang-tidy"  # Update with actual path to clang-tidy binary
COMPILE_COMMANDS_PATH = "/new/llvm-project/build/compile_commands.json"  # Update with the path to your compile_commands.json file
CLANG_INCLUDE_PATH = "/new/llvm-project/clang/include"  # Update with the Clang include path

# === Fetch PR Diff ===
url = f"https://api.github.com/repos/{OWNER}/{REPO}/pulls/{PR_NUMBER}"
diff_url = f"{url}.diff"

headers = {"Accept": "application/vnd.github.v3.diff"}

print(f"📥 Fetching diff from {diff_url}")
resp = requests.get(diff_url, headers=headers)

if resp.status_code != 200:
    print(f"❌ Failed to fetch PR diff: {resp.status_code} {resp.text}")
    sys.exit(1)

diff_text = resp.text
if not diff_text.strip():
    print("✅ No changes in the PR.")
    sys.exit(0)

# === Check if clang-tidy-diff.py exists ===
clang_tidy_diff_path = "clang-tidy-diff.py"
if not os.path.isfile(clang_tidy_diff_path):
    print(f"❌ {clang_tidy_diff_path} not found!")
    sys.exit(1)

# === Run clang-tidy-diff.py on PR diff ===
print("🧼 Running clang-tidy-diff.py on PR diff...")

# Prepare the environment for clang-tidy
env = os.environ.copy()
env["CXXFLAGS"] = f"-I{CLANG_INCLUDE_PATH}"  # Add Clang include path
env["CXX"] = CLANG_TIDY_PATH  # Set clang-tidy binary path

result = subprocess.run(
    ["python3", clang_tidy_diff_path, "-p1"],
    input=diff_text,
    text=True,
    capture_output=True,
    env=env  # Pass the environment variables
)

# === Output Results ===
if result.returncode == 0 and not result.stdout.strip():
    print("✅ No clang-tidy issues detected!")
    sys.exit(0)
else:
    print("🚨 Issues detected:")
    print("\n================= Diff Before clang-tidy =================")
    print(diff_text)
    print("\n================= Suggested Fixes =================")
    print(result.stdout)

    if result.stderr:
        print("\n⚠️ Error while running clang-tidy:")
        print(result.stderr)

    sys.exit(1)
