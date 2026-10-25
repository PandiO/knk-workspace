#!/usr/bin/env python3
"""End-to-end test of knk-deploy against a mock knk-alpha stack. Needs root, Docker with Compose v2 and alpine:3.22.

    sudo python3 scripts/nas-ops/stage-b/tests/test_knk_deploy.py

It builds tiny alpine images that stand in for the API, migrator, web app, MySQL and Minecraft, runs every command
of knk-deploy against them (including failures that must roll back) and removes everything at the end.
"""
import contextlib
import hashlib
import importlib.machinery
import importlib.util
import io
import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
PROG = os.path.join(HERE, '..', 'knk-deploy')
DISPATCH = os.path.join(HERE, '..', 'dispatch')
PLUGIN_KEY = 'pk-7f3c9e1a2b4d6f8091a3c5e7'
OLD_API, OLD_WEB = '00000000', '00000001'

results = []


def check(name, cond, detail=''):
    results.append((name, bool(cond)))
    print(('PASS ' if cond else 'FAIL ') + name + (f'  [{detail}]' if detail and not cond else ''), flush=True)


def load():
    loader = importlib.machinery.SourceFileLoader('knk_deploy', PROG)
    spec = importlib.util.spec_from_loader('knk_deploy', loader)
    m = importlib.util.module_from_spec(spec)
    loader.exec_module(m)
    return m


def sh(*args, **kw):
    return subprocess.run(args, check=True, capture_output=True, **kw)


def call(m, *argv, stdin=b''):
    m.sys.stdin = io.TextIOWrapper(io.BytesIO(stdin))
    out = io.StringIO()
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(io.StringIO()):
        code = m.main(list(argv))
    return code, json.loads(out.getvalue())


def tgz_source(files):
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode='w:gz') as t:
        for name, content in files.items():
            data = content.encode()
            info = tarfile.TarInfo('source/' + name)
            info.size = len(data)
            t.addfile(info, io.BytesIO(data))
    return buf.getvalue()


BASE = """\
services:
  mysql:
    image: alpine:3.22
    container_name: knk-alpha-mysql
    command: ["sh", "-c", "printf '#!/bin/sh\\ncat /state/migrations\\n' > /usr/local/bin/mysql && chmod +x /usr/local/bin/mysql && exec sleep infinity"]
    volumes:
      - {S}/state:/state:ro
      - {S}/secrets/mysql_root_password:/run/secrets/mysql_root_password:ro
    networks: [backend]
  api:
    image: knk-web-api:alpha-{OLD_API}
    container_name: knk-alpha-api
    user: "2002:2002"
    environment:
      AllowedHosts: "app.example"
    volumes:
      - {S}/secrets/jwt_secret:/run/secrets/jwt_secret:ro
    networks: [backend, webapi]
    security_opt: ["no-new-privileges:true"]
    cap_drop: [ALL]
  web:
    image: knk-web-app:alpha-{OLD_WEB}
    container_name: knk-alpha-web
    user: "101:101"
    environment:
      MODE: "a"
    networks: [webapi]
    security_opt: ["no-new-privileges:true"]
    cap_drop: [ALL]
  minecraft:
    image: alpine:3.22
    container_name: knk-alpha-minecraft
    user: "2001:2001"
    entrypoint: ["sh", "/data/start.sh"]
    volumes:
      - {S}/minecraft-data:/data
    networks: [backend, egress]
    security_opt: ["no-new-privileges:true"]
    cap_drop: [ALL]
    healthcheck:
      test: ["CMD", "test", "-f", "/tmp/up"]
      interval: 2s
      retries: 30
networks:
  backend:
    internal: true
  webapi:
    internal: true
  egress: {}
"""

START_SH = """\
#!/bin/sh
if [ -f /data/plugins/update/KnightsAndKings.jar ]; then mv /data/plugins/update/KnightsAndKings.jar /data/plugins/KnightsAndKings.jar; fi
if grep -q broken /data/plugins/KnightsAndKings/config.yml; then echo "[00:00:00 ERROR]: Error occurred while enabling KnightsAndKings"; exit 1; fi
echo "[00:00:00 INFO]: [KnightsAndKings] Enabling KnightsAndKings v0.1.0"
touch /tmp/up
exec sleep infinity
"""

API_DOCKERFILE = """\
FROM alpine:3.22 AS runtime
COPY source /src
USER 2002:2002
HEALTHCHECK --interval=2s --timeout=2s --retries=5 CMD test -f /src/ok
CMD ["sleep", "infinity"]
FROM alpine:3.22 AS migrator
COPY source /src
CMD ["sh", "-c", "for f in /src/Migrations/*.cs; do case $f in *.Designer.cs|*Snapshot.cs) continue;; esac; echo \\"Applying migration '$(basename $f .cs)'\\"; done; echo Done."]
"""

WEB_DOCKERFILE = """\
FROM alpine:3.22
COPY source /src
HEALTHCHECK --interval=2s --timeout=2s --retries=5 CMD test -f /src/ok
CMD ["sleep", "infinity"]
"""


def main():
    if os.geteuid() != 0:
        sys.exit('run as root')
    root = tempfile.mkdtemp(prefix='knk-deploy-test-')
    S = os.path.join(root, 'knk-alpha')
    m = load()
    m.STACK, m.COMPOSE, m.SECRETS = S, S + '/compose.yaml', S + '/secrets'
    m.MC_DATA, m.RELEASES = S + '/minecraft-data', S + '/releases'
    m.PORTAINER = root + '/portainer.yml'
    m.BUILD, m.STATE = root + '/build', root + '/state'
    m.INBOX, m.BACKUPS, m.LOG, m.LAST = m.STATE + '/inbox', m.STATE + '/backups', m.STATE + '/deploy.log', m.STATE + '/last.json'
    m.LOCK = root + '/lock'
    m.SNAPSHOT_DIR = root + '/snapshots'
    m.SNAPSHOT_CMD = root + '/snapshot.sh'
    m.KNK_OPS_COMPOSE = root + '/knk-ops-compose'
    m.ALLOWED_BIND_PREFIXES = (S + '/config/', S + '/minecraft-data', S + '/releases/')
    m.CONFIGS = {'knk': S + '/minecraft-data/plugins/KnightsAndKings/config.yml'}
    m.UPLOADS = {k: v for k, v in m.UPLOADS.items() if not k.startswith('config-')}
    m.UPLOADS['config-knk'] = ('sha256', 2 << 20, 'config-knk-{id}.yml')

    for d in ('secrets', 'state', 'config', 'minecraft-data/plugins/KnightsAndKings', 'minecraft-data/plugins/update'):
        os.makedirs(os.path.join(S, d), exist_ok=True)
    for name, value in (('jwt_secret', 'jwt-0123456789abcdef'), ('mysql_root_password', 'root-pass-abcdef12'), ('plugin_api_key', PLUGIN_KEY)):
        with open(os.path.join(S, 'secrets', name), 'w') as f:
            f.write(value + '\n')
    with open(S + '/state/migrations', 'w') as f:
        f.write('2\n')
    with open(S + '/minecraft-data/start.sh', 'w') as f:
        f.write(START_SH)
    with open(S + '/minecraft-data/plugins/KnightsAndKings/config.yml', 'w') as f:
        f.write(f'api:\n  auth:\n    type: apikey\n    api-key: "{PLUGIN_KEY}"\nmenus:\n  bedrock-transition-delay-ticks: 3\n')
    with zipfile.ZipFile(S + '/minecraft-data/plugins/KnightsAndKings.jar', 'w') as z:
        z.writestr('plugin.yml', 'name: KnightsAndKings\nversion: old\n')
    sh('chown', '-R', '2001:2001', S + '/minecraft-data')
    with open(m.COMPOSE, 'w') as f:
        f.write(BASE.replace('{S}', S).replace('{OLD_API}', OLD_API).replace('{OLD_WEB}', OLD_WEB))
    shutil.copyfile(m.COMPOSE, m.PORTAINER)
    with open(m.KNK_OPS_COMPOSE, 'w') as f:
        f.write('#!/bin/bash\nRECORDED_SHA=0000\necho\n')
    with open(m.SNAPSHOT_CMD, 'w') as f:
        f.write(f'#!/bin/sh\nmkdir -p {m.SNAPSHOT_DIR}/$(date -u +%Y%m%dT%H%M%SZ)-$1\necho done\n')
    os.chmod(m.SNAPSHOT_CMD, 0o755)
    for repo, files in (('knk-web-api', {'Dockerfile': API_DOCKERFILE, 'migrator-entrypoint.sh': '', 'appsettings.Production.json': '{}',
                                         'docker-entrypoint.sh': '', '.dockerignore': ''}),
                        ('knk-web-app', {'Dockerfile': WEB_DOCKERFILE, 'nginx.conf': '', '.dockerignore': ''})):
        d = os.path.join(m.BUILD, repo, '_files')
        os.makedirs(d)
        for n, c in files.items():
            with open(os.path.join(d, n), 'w') as f:
                f.write(c)
    # the "old" images
    for repo, tag, target, df in (('api', f'knk-web-api:alpha-{OLD_API}', 'runtime', API_DOCKERFILE), ('web', f'knk-web-app:alpha-{OLD_WEB}', None, WEB_DOCKERFILE)):
        ctx = tempfile.mkdtemp(dir=root)
        os.makedirs(ctx + '/source/Migrations')
        open(ctx + '/source/ok', 'w').close()
        with open(ctx + '/Dockerfile', 'w') as f:
            f.write(df)
        sh('docker', 'build', '-q', '-t', tag, *(['--target', target] if target else []), ctx)

    try:
        sh('docker', 'compose', '-f', m.COMPOSE, '--project-directory', S, 'up', '-d', '--wait')
        run_tests(m, S, root)
    finally:
        subprocess.run(['docker', 'compose', '-f', m.COMPOSE, '--project-directory', S, 'down', '-v', '--remove-orphans'], capture_output=True)
        subprocess.run('docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "^knk-web-(api|app|api-migrator):alpha-" | xargs -r docker rmi -f',
                       shell=True, capture_output=True)
        shutil.rmtree(root, ignore_errors=True)
    failed = [n for n, ok in results if not ok]
    print(f'\n{len(results) - len(failed)} passed, {len(failed)} failed')
    sys.exit(1 if failed else 0)


def compose_text(S):
    return open(S + '/compose.yaml').read()


def run_tests(m, S, root):
    # --- grammar ---
    for argv in (['status', 'x'], ['logs', 'mysql2'], ['upload', 'api-src', 'abc'], ['upload', 'compose', '../x'], ['restart', 'mysql'],
                 ['deploy-api', 'A' * 40], ['config-get', 'server-properties'], ['snapshot', 'Bad_Label'], ['rm', '-rf'], []):
        code, out = call(m, *argv)
        check(f'refused: {argv}', code == 64 and out['error'] == 'refused', out)

    # --- dispatcher denials (before sudo) ---
    for req in ('status; id', 'status && id', 'upload compose $(id)', 'STATUS', 'a b c d e', 'deploy-api ' + 'a' * 300, 'status\nid', '', 'bash'):
        p = subprocess.run(['bash', DISPATCH], env={'SSH_ORIGINAL_COMMAND': req, 'PATH': '/usr/bin:/bin'}, capture_output=True)
        check(f'dispatch denies {req[:30]!r}', p.returncode == 64 and b'denied' in p.stdout)

    # --- redaction ---
    secrets = m.secret_values()
    text = f'key: {PLUGIN_KEY}\nother: x'
    red = m.redact(text, secrets)
    check('redact hides the secret', PLUGIN_KEY not in red and '<<secret:plugin_api_key>>' in red)
    check('unredact restores it', m.unredact(red, secrets) == text)
    with contextlib.suppress(m.Refused):
        m.unredact('<<secret:nope>>', secrets)
        check('unredact refuses unknown tokens', False)

    # --- status / reads ---
    code, out = call(m, 'status')
    check('status ok', code == 0 and out['db_migrations'] == 2 and len(out['services']) == len(m.SERVICES), out)
    code, out = call(m, 'compose-get')
    check('compose-get', code == 0 and 'knk-alpha-api' in out['compose'])
    code, out = call(m, 'config-get', 'knk')
    check('config-get redacts the plugin key', code == 0 and PLUGIN_KEY not in out['content'] and '<<secret:plugin_api_key>>' in out['content'], out)
    code, out = call(m, 'logs', 'minecraft', '5')
    check('logs', code == 0 and 'Enabling KnightsAndKings' in out['log'])

    # --- compose policy ---
    base = compose_text(S)
    cases = {
        'privileged': base.replace('    container_name: knk-alpha-web\n', '    container_name: knk-alpha-web\n    privileged: true\n'),
        'published port': base.replace('    container_name: knk-alpha-web\n', '    container_name: knk-alpha-web\n    ports: ["8080:8080"]\n'),
        'docker.sock': base.replace('      - ' + S + '/secrets/jwt_secret:/run/secrets/jwt_secret:ro\n', '      - ' + S + '/secrets/jwt_secret:/run/secrets/jwt_secret:ro\n      - /var/run/docker.sock:/var/run/docker.sock\n'),
        'secret into web': base.replace('    networks: [webapi]\n', '    networks: [webapi]\n    volumes:\n      - ' + S + '/secrets/plugin_api_key:/k:ro\n'),
        'host path /etc': base.replace('    networks: [webapi]\n', '    networks: [webapi]\n    volumes:\n      - /etc:/hostetc:ro\n'),
        'cap_add': base.replace('    container_name: knk-alpha-web\n', '    container_name: knk-alpha-web\n    cap_add: [NET_ADMIN]\n'),
        'internal flip': base.replace('  backend:\n    internal: true\n', '  backend:\n    internal: false\n'),
        'api gains internet': base.replace('    networks: [backend, webapi]\n', '    networks: [backend, webapi, egress]\n'),
        'remove service': base.replace(base[base.index('  web:\n'):base.index('  minecraft:\n')], ''),
        'web to root': base.replace('    user: "101:101"\n', '    user: "0:0"\n'),
        'no nnp': base.replace('    security_opt: ["no-new-privileges:true"]\n    cap_drop: [ALL]\n  minecraft', '    cap_drop: [ALL]\n  minecraft'),
        'host network': base.replace('    networks: [webapi]\n', '    network_mode: host\n'),
        'latest image': base.replace(f'knk-web-app:alpha-{OLD_WEB}', 'nginx:latest'),
    }
    for name, text in cases.items():
        data = text.encode()
        h = hashlib.sha256(data).hexdigest()
        call(m, 'upload', 'compose', h, stdin=data)
        code, out = call(m, 'compose-apply', h)
        check(f'policy refuses: {name}', code == 65 and 'refused' == out.get('error'), out)
    check('compose unchanged after refusals', compose_text(S) == base)

    # --- compose-apply ok ---
    good = base.replace('      MODE: "a"\n', '      MODE: "b"\n')
    h = hashlib.sha256(good.encode()).hexdigest()
    code, out = call(m, 'upload', 'compose', h, stdin=good.encode())
    check('upload compose', code == 0 and out['sha256'] == h, out)
    code, out = call(m, 'upload', 'compose', '0' * 64, stdin=good.encode())
    check('upload refuses a hash mismatch', code == 65, out)
    code, out = call(m, 'compose-apply', h)
    check('compose-apply env change', code == 0 and out['services'] == ['web'], out)
    after = hashlib.sha256(open(m.COMPOSE, 'rb').read()).hexdigest()
    check('portainer copy + knk-ops hash', open(m.PORTAINER).read() == good and f'RECORDED_SHA={after}' in open(m.KNK_OPS_COMPOSE).read())
    env = sh('docker', 'inspect', '-f', '{{range .Config.Env}}{{println .}}{{end}}', 'knk-alpha-web').stdout.decode()
    check('web recreated with MODE=b', 'MODE=b' in env)

    # --- compose-apply that breaks health -> rollback ---
    bad = good.replace('    container_name: knk-alpha-web\n', '    container_name: knk-alpha-web\n    command: ["sh", "-c", "sleep 3; exit 1"]\n')
    h = hashlib.sha256(bad.encode()).hexdigest()
    call(m, 'upload', 'compose', h, stdin=bad.encode())
    code, out = call(m, 'compose-apply', h)
    check('broken compose rolls back', code == 1 and 'rolled back' in out.get('reason', '') and compose_text(S) == good, out)
    check('web healthy after rollback', m.state_of('web').get('health') == 'healthy')

    # --- rollback of the last good change ---
    code, out = call(m, 'rollback')
    check('rollback compose-apply', code == 0 and compose_text(S) == base, out)

    # --- config-apply ---
    code, out = call(m, 'config-get', 'knk')
    new = out['content'].replace('bedrock-transition-delay-ticks: 3', 'bedrock-transition-delay-ticks: 5')
    h = hashlib.sha256(new.encode()).hexdigest()
    call(m, 'upload', 'config-knk', h, stdin=new.encode())
    code, out = call(m, 'config-apply', 'knk', h)
    live = open(m.CONFIGS['knk']).read()
    check('config-apply restores the secret and restarts', code == 0 and 'ticks: 5' in live and PLUGIN_KEY in live, out)
    st = os.stat(m.CONFIGS['knk'])
    check('config owner kept', (st.st_uid, st.st_gid) == (2001, 2001))
    broken = new + 'broken: true\n'
    h = hashlib.sha256(broken.encode()).hexdigest()
    call(m, 'upload', 'config-knk', h, stdin=broken.encode())
    code, out = call(m, 'config-apply', 'knk', h)
    check('broken config rolls back', code == 1 and 'broken' not in open(m.CONFIGS['knk']).read(), out)

    # --- plugin ---
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, 'w') as z:
        z.writestr('plugin.yml', 'name: KnightsAndKings\nversion: new\n')
    jar = buf.getvalue()
    commit = 'ab' * 20
    code, out = call(m, 'upload', 'plugin-jar', commit, stdin=b'not a zip')
    check('upload refuses a non-jar', code == 65, out)
    code, out = call(m, 'upload', 'plugin-jar', commit, stdin=jar)
    check('upload plugin jar', code == 0, out)
    code, out = call(m, 'deploy-plugin', commit)
    live = S + '/minecraft-data/plugins/KnightsAndKings.jar'
    check('deploy-plugin swaps the jar', code == 0 and hashlib.sha256(open(live, 'rb').read()).hexdigest() == hashlib.sha256(jar).hexdigest(), out)
    check('release folder', os.path.isfile(S + f'/releases/plugin/{commit[:8]}/KnightsAndKings.jar'))
    code, out = call(m, 'rollback')
    check('rollback plugin', code == 0 and b'version: old' in zipfile.ZipFile(live).read('plugin.yml'), out)

    # --- api deploy with a migration ---
    commit = 'cd' * 20
    src = tgz_source({'ok': '', 'Migrations/20260101_A.cs': '', 'Migrations/20260101_A.Designer.cs': '', 'Migrations/20260102_B.cs': '',
                      'Migrations/20260103_C.cs': '', 'Migrations/KnKDbContextModelSnapshot.cs': ''})
    code, out = call(m, 'upload', 'api-src', commit, stdin=tgz_source({'../evil': ''}))
    check('upload refuses paths outside source/', code == 65, out)
    code, out = call(m, 'upload', 'api-src', commit, stdin=src)
    check('upload api source', code == 0, out)
    code, out = call(m, 'deploy-api', commit)
    check('deploy-api: migrator ran 3, image switched', code == 0 and out.get('migrations_applied') == ['20260101_A', '20260102_B', '20260103_C']
          and f'knk-web-api:alpha-{commit[:8]}' in compose_text(S) and m.state_of('api').get('health') == 'healthy', out)
    check('deploy-api took a snapshot', any(n.endswith(f'pre-api-{commit[:8]}') for n in os.listdir(m.SNAPSHOT_DIR)))
    with open(S + '/state/migrations', 'w') as f:
        f.write('9\n')
    commit2 = 'ce' * 20
    call(m, 'upload', 'api-src', commit2, stdin=src)
    code, out = call(m, 'deploy-api', commit2)
    check('deploy-api refuses an older build', code == 65 and 'older' in out.get('reason', ''), out)
    with open(S + '/state/migrations', 'w') as f:
        f.write('3\n')
    broken_src = tgz_source({'Migrations/20260101_A.cs': '', 'Migrations/20260102_B.cs': '', 'Migrations/20260103_C.cs': ''})  # no /src/ok -> unhealthy
    commit3 = 'cf' * 20
    call(m, 'upload', 'api-src', commit3, stdin=broken_src)
    code, out = call(m, 'deploy-api', commit3)
    check('unhealthy api build rolls back', code == 1 and f'knk-web-api:alpha-{commit[:8]}' in compose_text(S) and m.state_of('api').get('health') == 'healthy', out)

    # --- web deploy ---
    commit = 'ef' * 20
    call(m, 'upload', 'web-src', commit, stdin=tgz_source({'ok': ''}))
    code, out = call(m, 'deploy-web', commit)
    check('deploy-web', code == 0 and f'knk-web-app:alpha-{commit[:8]}' in compose_text(S), out)

    # --- snapshot / restart ---
    code, out = call(m, 'snapshot', 'manual-test')
    check('snapshot', code == 0 and out['snapshot'].endswith('manual-test'), out)
    code, out = call(m, 'restart', 'web')
    check('restart web', code == 0 and out['health']['health'] == 'healthy', out)

    # --- journal has no secret values ---
    log = open(m.LOG).read()
    check('journal written, no secrets in it', log.count('\n') > 10 and not any(v in log for v in m.secret_values().values()))


if __name__ == '__main__':
    main()
