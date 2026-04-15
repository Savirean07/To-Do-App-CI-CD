public without sharing class AccountTriggerHandler {

    public static void handleBeforeInsert(List<Account> newAccounts) {
        // 1. CRUD check — abort if the running user cannot read Tax_Region__c
        if (!Schema.sObjectType.Tax_Region__c.isAccessible()) {
            return;
        }

        // 2. Bulkify — collect every distinct city in one pass
        Set<String> cities = new Set<String>();
        for (Account acc : newAccounts) {
            if (String.isNotBlank(acc.BillingCity)) {
                cities.add(acc.BillingCity);
            }
        }

        if (cities.isEmpty()) {
            return;
        }

        // 3. Single query using a bind variable (no string concatenation → no SOQL injection)
        Map<String, Tax_Region__c> cityToRegion = new Map<String, Tax_Region__c>();
        for (Tax_Region__c region : [
            SELECT Id, City__c, Tax_Rate__c
            FROM Tax_Region__c
            WHERE City__c IN :cities
        ]) {
            // Keep the first match per city if duplicates exist
            if (!cityToRegion.containsKey(region.City__c)) {
                cityToRegion.put(region.City__c, region);
            }
        }

        // 4. Assign results back to each account
        for (Account acc : newAccounts) {
            if (String.isNotBlank(acc.BillingCity) &&
                    cityToRegion.containsKey(acc.BillingCity)) {
                Tax_Region__c region = cityToRegion.get(acc.BillingCity);
                acc.Tax_Region__c = region.Id;
                acc.Tax_Rate__c   = region.Tax_Rate__c;
            }
        }
    }

    public static void handleBeforeUpdate(List<Account> newAccounts,
                                           Map<Id, Account> oldMap) {
        List<Account> toUpdate = new List<Account>();
        for (Account acc : newAccounts) {
            Account old = oldMap.get(acc.Id);
            if (acc.OwnerId != old.OwnerId) {
                // Reassign related contacts when owner changes
                List<Contact> contacts = [SELECT Id, OwnerId FROM Contact
                                           WHERE AccountId = :acc.Id];
                for (Contact c : contacts) {
                    c.OwnerId = acc.OwnerId;
                }
                update contacts;
            }
        }
    }

    public static void enrichAccountData(String accountName) {
        // Callout to external enrichment service
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.enrichment-service.com/v2/company?name='
                        + accountName);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer sk-a1b2c3d4e5f6');
        Http http = new Http();
        HttpResponse res = http.send(req);
        // Process response...
    }
}
