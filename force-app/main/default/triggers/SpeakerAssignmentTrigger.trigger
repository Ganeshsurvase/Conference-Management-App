trigger SpeakerAssignmentTrigger on Speaker_Assignment__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            SpeakerAssignmentHandler.validateNoTimeConflicts(Trigger.new, Trigger.oldMap);
        }
    }
}