import { LightningElement, api, track } from 'lwc';
import checkSpeakerAvailability from '@salesforce/apex/SpeakerManagerController.checkSpeakerAvailability';
import createSessionAndAssignment from '@salesforce/apex/SpeakerManagerController.createSessionAndAssignment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BookSession extends LightningElement {
    @api selectedSpeaker;

    @track title = '';
    @track sessionDate = '';
    @track startTime = '';
    @track endTime = '';
    @track createDisabled = true;

    handleTitle(event) { this.title = event.target.value; }
    handleDate(event) { this.sessionDate = event.target.value; this.createDisabled = true; }
    handleStartTime(event) { this.startTime = event.target.value; this.createDisabled = true; }
    handleEndTime(event) { this.endTime = event.target.value; this.createDisabled = true; }

    showToast(title, message, variant='info') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    checkAvailability() {
        if (!this.selectedSpeaker) {
            this.showToast('Error', 'Select a speaker first', 'error');
            return;
        }
        if (!this.sessionDate) {
            this.showToast('Validation', 'Please choose a session date', 'error');
            return;
        }
        const chosen = new Date(this.sessionDate);
        const today = new Date();
        today.setHours(0,0,0,0);
        if (chosen <= today) {
            this.showToast('Validation', 'Date must be in the future', 'error');
            return;
        }
        if (!this.startTime || !this.endTime) {
            this.showToast('Validation', 'Provide start and end times', 'error');
            return;
        }
        // startTime and endTime are 'HH:MM' strings from lightning-input type=time
        if (this.startTime >= this.endTime) {
            this.showToast('Validation', 'Start time must be before end time', 'error');
            return;
        }

        checkSpeakerAvailability({
            speakerId: this.selectedSpeaker.Id,
            sessionDate: this.sessionDate,
            startTimeStr: this.startTime,
            endTimeStr: this.endTime
        })
        .then(result => {
            if (result === true) {
                this.showToast('Available', 'Speaker is available for this slot', 'success');
                this.createDisabled = false;
            } else {
                this.showToast('Unavailable', 'Slot is already booked, try another date/time', 'error');
                this.createDisabled = true;
            }
        })
        .catch(err => {
            const msg = err.body ? err.body.message : JSON.stringify(err);
            this.showToast('Error', msg, 'error');
        });
    }

    createAssignment() {
        if (!this.selectedSpeaker || !this.sessionDate || !this.startTime || !this.endTime) {
            this.showToast('Validation', 'Provide all booking details', 'error');
            return;
        }
        createSessionAndAssignment({
            speakerId: this.selectedSpeaker.Id,
            title: this.title,
            sessionDate: this.sessionDate,
            startTimeStr: this.startTime,
            endTimeStr: this.endTime
        })
        .then(assignId => {
            this.showToast('Success', 'Assignment created: ' + assignId, 'success');
            // reset creation UI
            this.title = '';
            this.sessionDate = '';
            this.startTime = '';
            this.endTime = '';
            this.createDisabled = true;
            // optionally dispatch an event so the speaker list updates (not implemented here)
        })
        .catch(err => {
            const msg = err.body ? err.body.message : JSON.stringify(err);
            this.showToast('Error', msg, 'error');
        });
    }
}

