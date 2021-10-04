async function query(qry, variables) {
    let response = await (await fetch("/graphql", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        redirect: 'follow',
        credentials: "same-origin",
        body: JSON.stringify({
            query: qry,
            variables,
        }),
    })).json();

    if (response.errors) {
        return Promise.reject(response.errors);
    }

    return Promise.resolve(response);
}

async function login(username, password) {
    return await query(`
    mutation login($username: String, $password: String) {
        authenticate(username:$username, password:$password)
    }`, { username: username, password: password })
}

async function register(username, password) {
    return await query(`
    mutation register($username: String, $password: String) {
        register(username:$username, password:$password)
    }`, { username: username, password: password })
}

async function logout(username, password) {
    return await query(`
    mutation logout {
        logout
    }`, {})
}

async function current_user() {
    return await query(`query {
            currentUser {
                username
                admin
            }
    }`, {});
}

async function ctfs() {
    return await query(`
    {
        organizers {
            name
            wtfs {
                id
                name
                description
            }
        }
    }`, {});
}

async function ctf(id) {
    return await query(`{
        wtf(id: ${id}) {
            name
            description
            challs {
                name
                points
                description
            }
        }
    }`)
}

async function create_ctf(name, description) {
    return await query(`
    mutation createWTF($name: String, $description: String) {
        createWTF(input: {name: $name, description: $description}) {
            id
        }
    }`,
        {
            name,
            description
        });
}


async function create_challenge(wtf, name, description, points, flag) {
    return await query(`
    mutation createChall($wtf: ID, $name: String, $description: String, $points: Int, $flag: String) {
        createChall(input: {
            wtf: $wtf,
            name: $name,
            description: $description,
            points: $points,
            flag: $flag
        }) {
            id
        }
    }`,
        {
            wtf,
            name,
            description,
            points,
            flag
        });
}