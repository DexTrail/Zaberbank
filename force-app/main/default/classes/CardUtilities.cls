public without sharing class CardUtilities {
    public static String getUniqueCardNumber(List<String> existingCardNumbers) {
        String cardNumber;
        Boolean isUnique;

        {
            cardNumber = generateCardNumber();
            isUnique = True;

            for(String existingCardNumber : existingCardNumbers) {
                if(existingCardNumber == cardNumber) {
                    isUnique = False;
                    break;
                }
            }
        } while (!isUnique);

        return cardNumber;
    }

    private static String generateCardNumber() {
    // Card number must not be random.
    // It should respond to special checksum algorithm.
    // But... not this time... We don't issue cards.
    return '4260 '
            + String.valueOf(Math.random() * 10000).split('\\.')[0].leftPad(4, '0') + ' '
            + String.valueOf(Math.random() * 10000).split('\\.')[0].leftPad(4, '0') + ' '
            + String.valueOf(Math.random() * 10000).split('\\.')[0].leftPad(4, '0');
    }
}
