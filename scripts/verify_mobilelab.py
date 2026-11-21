"""Exercise the Dart HTTP adapter before and after a real isolated CLI restart."""
import os
from pathlib import Path
import re
import shutil
import socket
import subprocess
import tempfile
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[1]


def verify():
    binary = os.environ.get('MOBILELAB_BIN') or shutil.which('mobilelab')
    if not binary:
        raise SystemExit('Install MobileLab 1.1.0 and set MOBILELAB_BIN or PATH.')
    binary = str(Path(binary).resolve())
    with tempfile.TemporaryDirectory(prefix='presta_mobilelab_') as directory:
        sandbox = Path(directory)
        with socket.socket() as listener:
            listener.bind(('127.0.0.1', 0))
            port = listener.getsockname()[1]
        config, count = re.subn(r'(?m)^(\s*port:\s*)\d+\s*$', rf'\g<1>{port}', (ROOT / 'mobilelab.yaml').read_text(), count=1)
        if count != 1:
            raise RuntimeError('Cannot configure isolated sandbox port')
        (sandbox / 'mobilelab.yaml').write_text(config)
        shutil.copytree(ROOT / 'mobilelab', sandbox / 'mobilelab', ignore=shutil.ignore_patterns('*.db*', '*.sqlite*', '*.log', '.state.json'))
        base = f'http://127.0.0.1:{port}'

        def stop(process):
            if process.poll() is None:
                process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)

        def start(log):
            process = subprocess.Popen([binary, 'start', '--headless'], cwd=sandbox, stdout=log, stderr=subprocess.STDOUT)
            try:
                for _ in range(100):
                    if process.poll() is not None:
                        raise RuntimeError('MobileLab exited before readiness')
                    try:
                        with urllib.request.urlopen(base + '/api/items', timeout=1) as response:
                            if response.status == 200:
                                return process
                    except OSError:
                        time.sleep(0.1)
                raise RuntimeError('MobileLab readiness timeout')
            except BaseException:
                stop(process)
                raise

        def adapter(phase):
            subprocess.run(['flutter', 'test', 'tool/integration/mobilelab_repository_test.dart', f'--dart-define=MOBILELAB_TEST_URL={base}', f'--dart-define=MOBILELAB_TEST_PHASE={phase}'], cwd=ROOT, check=True)

        with open(sandbox / 'integration.log', 'w+') as log:
            process = None
            try:
                process = start(log)
                adapter('create')
                stop(process)
                process = start(log)
                adapter('restart')
                print('PASS: real Dart adapter CRUD; SQLite loan history survived restart.')
            except BaseException:
                log.flush()
                log.seek(0)
                print(log.read())
                raise
            finally:
                if process is not None:
                    stop(process)


if __name__ == '__main__':
    verify()
