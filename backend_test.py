import requests
path = r'C:\Users\sushm\OneDrive\Desktop\IPV PROJECT\.venv\Lib\site-packages\ipykernel\resources\logo-32x32.png'
for url in ['http://127.0.0.1:5000/remove_background', 'http://192.168.1.184:5000/remove_background']:
    try:
        with open(path, 'rb') as f:
            r = requests.post(url, files={'image': f})
        print('URL:', url)
        print('Status:', r.status_code)
        print('Content-Type:', r.headers.get('content-type'))
        print('Body:', r.text[:500])
    except Exception as e:
        print('URL:', url, 'ERROR:', e)
