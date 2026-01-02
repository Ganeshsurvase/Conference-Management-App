public with sharing class SpeakerAssignmentHandler {
    public class SessionInfo {
        public Id assignmentId;
        public Id speakerId;
        public Id sessionId;
        public Date sessionDate;
        public Time startTime;
        public Time endTime;
        public SessionInfo(Id aId, Id sId, Id sessId, Date d, Time st, Time et) {
            assignmentId = aId;
            speakerId = sId;
            sessionId = sessId;
            sessionDate = d;
            startTime = st;
            endTime = et;
        }
    }

    public static void validateNoTimeConflicts(List<Speaker_Assignment__c> newList, Map<Id, Speaker_Assignment__c> oldMap) {
    
        Set<Id> speakerIds = new Set<Id>();
        Set<Id> sessionIds = new Set<Id>();

        for (Speaker_Assignment__c a : newList) {
            if (a.Speaker__c != null && a.Session__c != null) {
                speakerIds.add(a.Speaker__c);
                sessionIds.add(a.Session__c);
            }
        }

        if (speakerIds.isEmpty() || sessionIds.isEmpty()) {
            // Nothing to validate
            return;
        }

       
        Map<Id, Session__c> sessionsMap = new Map<Id, Session__c>();
        for (Session__c s : [
            SELECT Id, Session_Date__c, Start_Time__c, End_Time__c
            FROM Session__c
            WHERE Id IN :sessionIds
        ]) {
            sessionsMap.put(s.Id, s);
        }

       
        List<Speaker_Assignment__c> existingAssignments = [
            SELECT Id, Speaker__c, Session__c,
                   Session__r.Session_Date__c,
                   Session__r.Start_Time__c,
                   Session__r.End_Time__c
            FROM Speaker_Assignment__c
            WHERE Speaker__c IN :speakerIds
            AND Session__c != NULL
        ];

        
        Map<Id, List<SessionInfo>> existingBySpeaker = new Map<Id, List<SessionInfo>>();
        for (Speaker_Assignment__c ex : existingAssignments) {
           
            Session__c s = ex.Session__r;
            if (s == null) continue; 
            SessionInfo info = new SessionInfo(ex.Id, ex.Speaker__c, ex.Session__c, s.Session_Date__c, s.Start_Time__c, s.End_Time__c);
            if (!existingBySpeaker.containsKey(ex.Speaker__c)) existingBySpeaker.put(ex.Speaker__c, new List<SessionInfo>());
            existingBySpeaker.get(ex.Speaker__c).add(info);
        }

       
        Map<Id, SessionInfo> newAssignmentInfoMap = new Map<Id, SessionInfo>(); 
        List<SessionInfo> newSessionInfos = new List<SessionInfo>();

        
        Integer idx = 0;
        for (Speaker_Assignment__c a : newList) {
            idx++;
            if (a.Speaker__c == null || a.Session__c == null) continue;
            Session__c s = sessionsMap.get(a.Session__c);
            if (s == null) continue;
            
            Id pseudoId = a.Id;
            SessionInfo info = new SessionInfo(pseudoId, a.Speaker__c, a.Session__c, s.Session_Date__c, s.Start_Time__c, s.End_Time__c);
            newSessionInfos.add(info);
            newAssignmentInfoMap.put(pseudoId, info);
        }

      
        for (Integer i=0; i<newSessionInfos.size(); i++) {
            SessionInfo newInfo = newSessionInfos[i];
            if (newInfo.sessionDate == null || newInfo.startTime == null || newInfo.endTime == null) {
             
                continue;
            }
            
            List<SessionInfo> existingList = existingBySpeaker.get(newInfo.speakerId);
            if (existingList != null) {
                for (SessionInfo ex : existingList) {
                   
                    if (ex.sessionId == newInfo.sessionId) continue;
                    if (ex.sessionDate == null || ex.startTime == null || ex.endTime == null) continue;
                    if (ex.sessionDate == newInfo.sessionDate) {
                        if (isOverlap(newInfo.startTime, newInfo.endTime, ex.startTime, ex.endTime)) {
                            
                            addErrorToMatchingNewRecord(newList, newInfo, 'Speaker is already booked for this time.');
                        }
                    }
                }
            }
           
            for (Integer j=0; j<newSessionInfos.size(); j++) {
                if (i==j) continue;
                SessionInfo other = newSessionInfos[j];
                if (other.speakerId != newInfo.speakerId) continue;
                if (other.sessionDate == null || other.startTime == null || other.endTime == null) continue;
                if (other.sessionDate == newInfo.sessionDate) {
                    if (isOverlap(newInfo.startTime, newInfo.endTime, other.startTime, other.endTime)) {
                        addErrorToMatchingNewRecord(newList, newInfo, 'Speaker is already booked for this time (conflicts with another assignment in this batch).');
                    }
                }
            }
        }
    }

    private static Boolean isOverlap(Time aStart, Time aEnd, Time bStart, Time bEnd) {
     

        if (aStart == null || aEnd == null || bStart == null || bEnd == null) return false;
        if (aStart >= aEnd || bStart >= bEnd) {
            
            return false;
        }
        return (aStart < bEnd) && (aEnd > bStart);
    }

    private static void addErrorToMatchingNewRecord(List<Speaker_Assignment__c> newList, SessionInfo info, String message) {
       
        for (Speaker_Assignment__c a : newList) {
            if (a.Speaker__c == info.speakerId && a.Session__c == info.sessionId) {
                a.addError(message);
            }
        }
    }
}