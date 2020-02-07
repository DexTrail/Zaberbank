trigger CardCreation on Card__c (before insert) {
    Card__c[] existingCards = [SELECT Card_Number__c FROM Card__c];

    List<String> existingCardNumbers = new List<String>();

    for(Card__c card : existingCards) {
        existingCardNumbers.add(card.Card_Number__c);
    }

    for(Card__c card : Trigger.new) {
        card.Card_Number__c = CardUtilities.getUniqueCardNumber(existingCardNumbers);
        existingCardNumbers.add(card.Card_Number__c);

        // Debit cards don't have overdraft allowed during creation
        if(card.Type__c == 'Debit') {
            card.Limit__c = 0;
        }
    }
}