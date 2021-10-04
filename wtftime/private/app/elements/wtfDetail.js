import { LitElement, html } from '../web_modules/lit.js';
import '../query.js';
import './wtf.js'
import './challengeCard.js'

export class WtfDetail extends LitElement {
    constructor() {
        super();
        this._id = 0;
        this.name = "";
        this.description = "";
        this.challs = [];
    }

    set id(val) {
        this._id = val;
        ctf(val)
            .then((result) => {
                this.name = result.data.wtf.name;
                this.description = result.data.wtf.description;
                this.challs = result.data.wtf.challs;
                this.requestUpdate();
            })
            .catch((_) => {});
    }

    get id() {
        return this._id;
    }
    
    static get properties() {
        return {
            id: {},
        }
    }

    render() {
        return html`
        <link rel="stylesheet" href="/css/bootstrap.min.css" />
        <wtf-short name=${this.name} description=${this.description}></wtf-short>
        <div class="row pt-3">
            ${this.challs.map((chall) => 
                html`<challenge-card
                    name=${chall.name}
                    points=${chall.points}
                    description=${chall.description}
                    class="col-3 mb-3">
                </challenge-card>`
            )}<a class="btn btn-primary" href="#new-chall/${this.id}" role="button"><div class="align-middle">Add</div></a>
            </a>
        </div>
        `
    }
}

customElements.define("wtf-detail", WtfDetail);