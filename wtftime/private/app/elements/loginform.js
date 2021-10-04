import { LitElement, html } from '../web_modules/lit.js';
import '../query.js';

class LoginForm extends LitElement {
    constructor() {
        super();
        this.message = "";
        this.alert_type = "danger";
    }

    get properties() {
		return {
			message: {
				type: String,
                attribute: false
			}
		}
    }

    render() {
        return html`
        <link rel="stylesheet" href="/css/bootstrap.min.css" />
        <form @onsubmint="${this._login}">
            <div class="form-group">
                <label for="username">Email address</label>
                <input type="text" class="form-control" id="username" placeholder="Username">
            </div>
            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" class="form-control" id="password" placeholder="Password">
            </div>
            ${this.message == "" ? html`` : html`<div class="alert alert-${this.alert_type}" role="alert">${this.message}</div>`}
            <button type="submit" class="btn btn-default" @click="${this._login}">Submit</button>
            <button type="button" class="btn btn-default" @click="${this._register}">Register</button>
        </form>
        `
    }

    get username() {
        return this.shadowRoot.getElementById("username").value;
        
    }

    get password() {
        return this.shadowRoot.getElementById("password").value;
    }

    _register(e) {

        register(this.username, this.password)
            .then((_) => {
                this.message = "Registered";
                this.alert_type = "success";
                this.requestUpdate();
            })
            .catch((e) => {
                this.message = "Registration failed";
                this.alert_type = "danger";
                this.requestUpdate()
            });
        this.requestUpdate();
    }

    _login(e) {
        login(this.username, this.password)
            .then((_) => {
                this.message = "";
                this.requestUpdate();
                this.dispatchEvent(new CustomEvent("login", {bubbles: true, composed: true}));
                window.location.hash = '#';
            })
            .catch((e) => {
                this.message = "Authentication failed";
                this.alert_type = "danger";
                this.requestUpdate()
            });
    }
}

customElements.define("login-form", LoginForm);