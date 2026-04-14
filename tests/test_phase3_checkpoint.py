import subprocess
import json
import os
import pytest

def test_actions_pinned_to_sha():
    """All GitHub Actions must use SHA hashes not tags"""
    with open('.github/workflows/security-pipeline.yml', 'r') as f:
        content = f.read()
    import re
    uses = re.findall(r'uses:\s+(\S+)', content)
    for action in uses:
        assert '@' in action
        sha = action.split('@')[1]
        assert len(sha) == 40, f"{action} is not pinned to a SHA"

def test_opa_policy_denies_root():
    import shutil
    if not shutil.which('opa'):
        pytest.skip('OPA not installed')
    """OPA policy must deny root user"""
    result = subprocess.run(
        ['opa', 'eval', '-d', 'opa/container_policy.rego', '-I', 'data.container.security.deny'],
        input='{"user": "root"}',
        capture_output=True, text=True
    )
    output = json.loads(result.stdout)
    denials = output['result'][0]['expressions'][0]['value']
    assert len(denials) > 0

def test_opa_policy_allows_nonroot():
    import shutil
    if not shutil.which('opa'):
        pytest.skip('OPA not installed')
    """OPA policy must allow non-root user"""
    result = subprocess.run(
        ['opa', 'eval', '-d', 'opa/container_policy.rego', '-I', 'data.container.security.deny'],
        input='{"user": "1001"}',
        capture_output=True, text=True
    )
    output = json.loads(result.stdout)
    denials = output['result'][0]['expressions'][0]['value']
    assert len(denials) == 0

def test_sbom_exists():
    """CycloneDX SBOM must exist and contain components"""
    assert os.path.exists('sbom.json')
    with open('sbom.json', 'r') as f:
        data = json.load(f)
    assert len(data.get('components', [])) > 0

def test_cosign_public_key_exists():
    """Cosign public key must be committed to repo"""
    assert os.path.exists('cosign.pub')
    with open('cosign.pub', 'r') as f:
        content = f.read()
    assert 'PUBLIC KEY' in content
