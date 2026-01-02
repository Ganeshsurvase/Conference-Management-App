public with sharing class SpeakerManagerController {
    @AuraEnabled(cacheable=true)
    public static List<Speaker__c> getSpeakers(String name, String speciality) {
        String nm = (name == null) ? '' : name.trim();
        String spec = (speciality == null) ? '' : speciality.trim();
        String baseQuery = 'SELECT Id, Name, Email__c, Bio__c, Speciality__c FROM Speaker__c WHERE Id != NULL';
        List<String> filters = new List<String>();
        if (nm != '') {
            filters.add('Name LIKE \'%' + String.escapeSingleQuotes(nm) + '%\'');
        }
        if (spec != '') {
            filters.add('Speciality__c = \'' + String.escapeSingleQuotes(spec) + '\'');
        }
        if (!filters.isEmpty()) {
            baseQuery += ' AND ' + String.join(filters, ' AND ');
        }
        baseQuery += ' ORDER BY Name LIMIT 200';
        return Database.query(baseQuery);
    }

   
    private static Time parseTime(String hhmm) {
        if (String.isBlank(hhmm)) return null;
        List<String> parts = hhmm.split(':');
        if (parts.size() < 2) return null;
        Integer h = Integer.valueOf(parts[0]);
        Integer m = Integer.valueOf(parts[1]);
        return Time.newInstance(h, m, 0, 0);
    }

    @AuraEnabled
    public static Boolean checkSpeakerAvailability(Id speakerId, Date sessionDate, String startTimeStr, String endTimeStr) {
        if (speakerId == null || sessionDate == null || String.isBlank(startTimeStr) || String.isBlank(endTimeStr)) {
            throw new AuraHandledException('Required parameters missing.');
        }
        Time startT = parseTime(startTimeStr);
        Time endT = parseTime(endTimeStr);
        if (startT == null || endT == null) throw new AuraHandledException('Invalid time format. Use HH:mm');

        
        List<Speaker_Assignment__c> assigns = [
            SELECT Id, Session__c, Session__r.Session_Date__c, Session__r.Start_Time__c, Session__r.End_Time__c
            FROM Speaker_Assignment__c
            WHERE Speaker__c = :speakerId
            AND Session__c != NULL
            AND Session__r.Session_Date__c = :sessionDate
        ];

        for (Speaker_Assignment__c sa : assigns) {
            Session__c s = sa.Session__r;
            if (s == null) continue;
            Time exStart = s.Start_Time__c;
            Time exEnd = s.End_Time__c;
            if (exStart == null || exEnd == null) continue;
            if ((startT < exEnd) && (endT > exStart)) {
                return false; // conflict found
            }
        }
        return true; // no conflicts
    }

    @AuraEnabled
    public static Id createSessionAndAssignment(Id speakerId, String title, Date sessionDate, String startTimeStr, String endTimeStr) {
        if (speakerId == null || sessionDate == null || String.isBlank(startTimeStr) || String.isBlank(endTimeStr)) {
            throw new AuraHandledException('Required parameters missing.');
        }
        Time startT = parseTime(startTimeStr);
        Time endT = parseTime(endTimeStr);
        if (startT == null || endT == null) throw new AuraHandledException('Invalid time format. Use HH:mm');

       
        Session__c s = new Session__c();
        s.Title__c = String.isBlank(title) ? 'Booked Session' : title;
        s.Session_Date__c = sessionDate;
        s.Start_Time__c = startT;
        s.End_Time__c = endT;
        insert s;

       
        Speaker_Assignment__c sa = new Speaker_Assignment__c();
        sa.Session__c = s.Id;
        sa.Speaker__c = speakerId;
        insert sa;

        return sa.Id;
    }
}