import { LitElement, html } from '../web_modules/lit.js';
import './loginform.js';
import './overview.js';
import './newWtfForm.js';
import './wtfDetail.js';
import './newChallengeForm.js'

class Navbar extends LitElement {
    constructor() {
        super();
		this.route = decodeURI(window.location.hash).split('/');

        this.routes = {
            '#404': html`<h1>404</h1>`,
            '#login': html`<login-form></login-form>`,
            '#new-wtf': html`<new-wtf></new-wtf>`,
            '#new-chall': () => html`<new-chall wtf=${this.route[1]}></new-chall>`,
            '#wtf': () => html`<wtf-detail id=${this.route[1]}></wtf-detail>`,
            '': html`<wtf-overview name="foo"></wtf-overview>`,
        };

        this.onHashChange = (e) => {
            this.route = decodeURI(window.location.hash).split('/');
            this.requestUpdate();
        }

        this.username = null;
        this.updateUser();
    }

    updateUser() {
        current_user()
            .then((response) => {
                this.username = response.data.currentUser.username;
                this.requestUpdate();
            })
            .catch(() => {
                this.username = null;
                this.requestUpdate();
            });
    }

    connectedCallback() {
        super.connectedCallback();
        window.addEventListener("hashchange", this.onHashChange);
        this.addEventListener("login", this.onLogin);
    }

    disconnectedCallback() {
        super.connectedCallback();
        window.removeEventListener("hashchange", this.onHashChange);
        this.removeEventListener("login", this.onLogin);
    }

    onLogin(e) {
        this.updateUser()
    }

	static get properties() {
		return {
			route: {
				type: String,
                attribute: false,
			},
            user: {}
		}
	}

    render() {
        console.log(`route: ${this.route}`)
        return html`
        <link rel="stylesheet" href="/css/bootstrap.min.css" />
        <nav class="navbar navbar-expand-lg navbar-light bg-light">
            <div class="container">
                <a class="navbar-brand nav-link" href="#">WTFTime</a>
                <ul class="nav">
                    <li class="nav-item"><a  class="nav-link" href="#new-wtf">New WTF</a></li>
                    <li class="nav-item">${this.username
                        ? html`<a class="nav-link" href="#" @click="${this._logout}">Logout ${this.username}</a>`
                        : html`<a  class="nav-link" href="#login">login</a>`}
                    </li>
                </ul>
                <ul class="nav">
                </ul>
            </div>
        </nav>
        <div class="container">
        ${this.routes.hasOwnProperty(this.route[0])
            ? ( this.routes[this.route[0]] instanceof Function
                ? this.routes[this.route[0]]()
                : this.routes[this.route[0]])
            : `404`}
        </div>`
    }

    _logout(e) {
        logout()
            .then((_) => this.updateUser())
            .catch((_) => this.updateUser());
    }
}

customElements.define("app-navbar", Navbar);