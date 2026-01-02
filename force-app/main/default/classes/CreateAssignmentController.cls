public with sharing class CreateAssignmentController {

    @AuraEnabled
    public static Id createAssignment(Id speakerId, Id sessionId){
        Speaker_Assignment__c sa = new Speaker_Assignment__c(
            Speaker__c = speakerId,
            Session__c = sessionId
        );
        insert sa;
        return sa.Id;
    }
}