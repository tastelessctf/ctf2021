import { LitElement, html } from '../web_modules/lit.js';

class CreateChallForm extends LitElement {
    constructor() {
        super();
        this.wtf = 0;
    }

    static get properties() {
        return {
            wtf: { type: Number },
        }
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
            <div class="form-group">
                <label for="flag">Flag</label>
                <input type="text" class="form-control" id="flag" placeholder="Flag">
            </div>
            <div class="form-group">
                <label for="exampleFormControlSelect1">Points</label>
                <select class="form-control" id="points">
                    <option>100</option>
                    <option>200</option>
                    <option>300</option>
                    <option>400</option>
                    <option>500</option>
                </select>
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

    get points() {
        return parseInt(this.shadowRoot.getElementById("points").value)
    }

    get flag() {
        return this.shadowRoot.getElementById("flag").value 
    }

    _save(e) {
        create_challenge(this.wtf, this.name, this.description, this.points, this.flag)
            .then((_) => { window.location.hash = `#wtf/${this.wtf}`; })
            .catch((errors) => alert(errors.map((error) => error.message).join('\n')));
    }
}

customElements.define("new-chall", CreateChallForm);