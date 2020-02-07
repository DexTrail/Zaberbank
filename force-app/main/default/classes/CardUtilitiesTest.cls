@isTest
private class CardUtilitiesTest {
    @isTest
    static void cardNumberTest() {
        System.debug('cardNumberTest() started');

        List<String> existingCards = new List<String>();
        String cardNumber, substring;

        for(Integer i = 0; i < 500; i++) {
            cardNumber = CardUtilities.getUniqueCardNumber(existingCards);

            System.assertEquals(19, cardNumber.length());

            System.assertEquals(' ', cardNumber.substring(4, 5));
            System.assertEquals(' ', cardNumber.substring(9, 10));
            System.assertEquals(' ', cardNumber.substring(14, 15));

            substring = cardNumber.substring(0, 4);
            System.assertEquals(substring, String.valueOf(Integer.valueOf(substring)).leftPad(4, '0'));

            substring = cardNumber.substring(5, 9);
            System.assertEquals(substring, String.valueOf(Integer.valueOf(substring)).leftPad(4, '0'));

            substring = cardNumber.substring(10, 14);
            System.assertEquals(substring, String.valueOf(Integer.valueOf(substring)).leftPad(4, '0'));

            substring = cardNumber.substring(15, 19);
            System.assertEquals(substring, String.valueOf(Integer.valueOf(substring)).leftPad(4, '0'));

            System.assert(checkNumberUnique(cardNumber, existingCards));

            existingCards.add(cardNumber);
        }

        System.assertEquals(500, existingCards.size());

        System.debug('cardNumberTest() passed');
    }

    private static Boolean checkNumberUnique(String uniqueCardNumber, List<String> cardNumbers) {
        for(String cardNumber : cardNumbers) {
            if(cardNumber.equals(uniqueCardNumber)) {
                return False;
            }
        }

        return True;
    }
}
