"""Generate ElevenLabs narration for every spoken text in the app.

Runs inside GitHub Actions (see .github/workflows/voices.yml).
Needs env: ELEVENLABS_API_KEY, ELEVENLABS_VOICE_ID. Optional: ELEVENLABS_MODEL.
Resumable: texts already listed in assets/audio/voice/index.json are skipped,
so if the monthly quota runs out, run it again later and it continues.
"""
import json, os, re, subprocess, sys, tempfile, time, urllib.request, urllib.error

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
VOICE_DIR = os.path.join(ROOT, 'assets', 'audio', 'voice')
INDEX = os.path.join(VOICE_DIR, 'index.json')
CONTENT = os.path.join(ROOT, 'assets', 'content', 'book12.json')

KEY = os.environ['ELEVENLABS_API_KEY'].strip()
VOICE = os.environ['ELEVENLABS_VOICE_ID'].strip()
MODEL = os.environ.get('ELEVENLABS_MODEL', '').strip() or 'eleven_multilingual_v2'


def spoken_texts():
    d = json.load(open(CONTENT, encoding='utf-8'))
    out = []
    for w in d['words']:
        out += [w['word'], w['example']]
    for l in d['lessons']:
        for s in l['steps']:
            for k in ('audio', 'example'):
                if s.get(k):
                    out.append(s[k])
    seen = []
    for t in out:
        if t not in seen:
            seen.append(t)
    return seen


def speakable(text):
    # Read blanks as a short pause instead of "underscore".
    return re.sub(r'_{2,}', '…', text)


def tts(text):
    req = urllib.request.Request(
        f'https://api.elevenlabs.io/v1/text-to-speech/{VOICE}?output_format=mp3_44100_128',
        data=json.dumps({
            'text': speakable(text),
            'model_id': MODEL,
            'voice_settings': {'stability': 0.5, 'similarity_boost': 0.75},
        }).encode(),
        headers={'xi-api-key': KEY, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg'},
    )
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            body = e.read().decode('utf-8', 'replace')
            if e.code == 429 and 'quota' not in body.lower():
                time.sleep(5 * (attempt + 1))
                continue
            raise RuntimeError(f'HTTP {e.code}: {body[:300]}')
    raise RuntimeError('Too many retries')


def main():
    index = json.load(open(INDEX, encoding='utf-8-sig'))
    used = [int(m.group(1)) for f in os.listdir(VOICE_DIR) if (m := re.match(r'eleven-(\d+)\.', f))]
    n = max(used, default=0)
    todo = [t for t in spoken_texts() if t not in index]
    print(f'{len(todo)} clips to generate ({sum(len(t) for t in todo)} characters)')
    made = 0
    try:
        for text in todo:
            raw = tts(text)
            n += 1
            name = f'eleven-{n:02d}.mp3'
            with tempfile.NamedTemporaryFile(suffix='.mp3', delete=False) as tmp:
                tmp.write(raw)
            # Match the bundled clips: mono, 22.05 kHz, consistent loudness.
            subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', tmp.name,
                            '-af', 'loudnorm=I=-18:TP=-1.5:LRA=11', '-ac', '1', '-ar', '22050',
                            '-b:a', '64k', os.path.join(VOICE_DIR, name)], check=True)
            os.unlink(tmp.name)
            index[text] = name
            made += 1
            if made % 25 == 0:
                print(f'  {made}/{len(todo)}')
    except Exception as e:  # keep what was made; the next run continues from here
        print(f'Stopped early: {e}', file=sys.stderr)
    finally:
        json.dump(index, open(INDEX, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
        print(f'Generated {made} of {len(todo)} clips')
    if made == 0 and todo:
        sys.exit(1)


if __name__ == '__main__':
    main()
