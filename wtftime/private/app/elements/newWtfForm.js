import { LitElement, html } from '../web_modules/lit.js';

class CreateWTFForm extends LitElement {
    constructor() {
        super();
    }

    render() {
        return html`
        <link rel="stylesheet" href="/css/bootstrap.min.css" />
        <form @onsubmint="${this._save}">
            <div class="form-group">
                <label for="name">Name</label>
                <input type="text" class="form-control" id="name" placeholder="Name">
            </div>
            <div class="form-group">
                <label for="description">Description</label>
                <textarea rows=10 class="form-control" id="description" placeholder="Description"></textarea>
            </div>
            <button type="submit" class="btn btn-default" @click="${this._save}">Submit</button>
        </form>
        `
    }

    get name() {
        return this.shadowRoot.getElementById("name").value
    }

    get description() {
        return this.shadowRoot.getElementById("description").value
    }

    _save(e) {
        create_ctf(this.name, this.description)
            .then((_) => { window.location.hash = "#"; })
            .catch((errors) => alert(errors.map((error) => error.message).join('\n')));
    }
}

customElements.define("new-wtf", CreateWTFForm);