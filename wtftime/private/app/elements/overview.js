import { LitElement, html } from '../web_modules/lit.js';
import '../query.js';
import { Organizer} from './organizer.js';

class Overview extends LitElement {
    constructor() {
        super();
        this.organizers = [];
        ctfs().then((resp) => {
            this.organizers = resp.data.organizers;
            this.requestUpdate();
        }).catch((err) => {});
    }

    render() {
        return html`
        <link rel="stylesheet" href="/css/bootstrap.min.css" />

        <h1>CTFs</h1>
        ${this.organizers.map(
            (organizer) => {
                let org = new Organizer();
                org.name = organizer.name;
                org.wtfs = organizer.wtfs;
                return org;
            })
        }
        `
    }
}

customElements.define("wtf-overview", Overview);