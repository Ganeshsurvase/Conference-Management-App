import { LightningElement, api, wire, track } from 'lwc';
import getSpeakers from '@salesforce/apex/SpeakerManagerController.getSpeakers';

const columns = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Email', fieldName: 'Email__c', type: 'email' },
    { label: 'Speciality', fieldName: 'Speciality__c' },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Book Session', name: 'book' },
                { label: 'View', name: 'view' }
            ]
        }
    }
];

export default class SpeakerList extends LightningElement {
    @api nameFilter = '';
    @api specialityFilter = '';

    @track speakers;
    @track error;
    columns = columns;

    
    @wire(getSpeakers, { name: '$nameFilter', speciality: '$specialityFilter' })
    wiredSpeakers({ error, data }) {
        if (data) {
            this.speakers = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : JSON.stringify(error);
            this.speakers = undefined;
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'book') {
            
            const selEvent = new CustomEvent('selected', { detail: row });
            this.dispatchEvent(selEvent);
        } else if (actionName === 'view') {
          
            const selEvent = new CustomEvent('selected', { detail: row });
            this.dispatchEvent(selEvent);
        }
    }
}
