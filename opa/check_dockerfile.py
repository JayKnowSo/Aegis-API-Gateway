import subprocess
import json
import sys
import re

# Extract USER from Dockerfile
user = None
with open('Dockerfile', 'r') as f:
    for line in f:
        match = re.match(r'^\s*USER\s+(\S+)', line)
        if match:
            user = match.group(1)

print(f"Dockerfile USER: {user}")

# Run OPA policy
input_data = json.dumps({"user": user or ""})
result = subprocess.run(
    ['opa', 'eval', '-d', 'opa/container_policy.rego', '-I', 'data.container.security.deny'],
    input=input_data,
    capture_output=True,
    text=True
)

output = json.loads(result.stdout)
denials = output['result'][0]['expressions'][0]['value']

if denials:
    print(f"POLICY VIOLATION: {denials}")
    sys.exit(1)
else:
    print("OPA policy passed: container runs as non-root")
    sys.exit(0)
