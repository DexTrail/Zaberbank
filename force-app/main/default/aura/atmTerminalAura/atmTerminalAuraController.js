({
    initATMs: function(component) {
        let action = component.get("c.getAllATMs");
        let atms = [];

        action.setCallback(this, function(response) {
            if(response.getState() == 'SUCCESS') {
                let allValues = response.getReturnValue();
                for(let i = 0; i < allValues.length; i++) {
                    atms.push({
                        "label": allValues[i].Name,
                        "value": allValues[i].Id
                    });
                }
            } else if(response.getState() == 'ERROR') {
                alert("An ERROR occured while getting ATMs.");
            }

            component.set("v.atms", atms);
        });

        $A.enqueueAction(action);
    },

    initCards: function (component) {
        let action = component.get("c.getAllCards");
        let cards = [];

        action.setCallback(this, function(response) {
            let state = response.getState();
            if(state == 'SUCCESS') {
                let allValues = response.getReturnValue();
                for(let i = 0; i < allValues.length; i++) {
                    cards.push({
                        "label": allValues[i].Card_Number__c,
                        "value": allValues[i].Id,
                        "firstName":allValues[i].ContactId__r.FirstName,
                        "lastName":allValues[i].ContactId__r.LastName,
                        "currencyCode": allValues[i].CurrencyId__r.Name,
                        "exrate": allValues[i].CurrencyId__r.Ex_Rate__c
                    });
                }
            } else if(state == 'ERROR') {
                alert("An ERROR occured while getting cards.");
            }

            component.set("v.cards", cards);
        });

        $A.enqueueAction(action);
    },

    handleATMChange: function (component, event, helper) {
        let selectedOptionValue = event.getParam("value");

        helper.clearData(component);

        component.set("v.selectedAtm", selectedOptionValue);
        helper.setTerminalText(component, "Welcome!", 2000, "Select a card");

        helper.initCurrencies(component);
    },

    handleCardChange: function (component, event, helper) {
        component.set("v.requestPIN", true);
        helper.setTerminalText(component, "Input PIN");

        helper.setCardCurrency(component);
    },

    handleCurrencyChange: function (component, event, helper) {
        let selectedOptionValue = event.getParam("value");
        component.set("v.selectedCurrency", selectedOptionValue);
        helper.setTerminalText(component, "Input amount");

        helper.showExRate(component);
    },

    handleButtonClick: function (component, event, helper) {
        let button = event.getSource().get("v.value");
        switch(button) {
            case 'balance':
                helper.getBalance(component);
                break;
            case 'withdraw':
                helper.withdraw(component);
                break;
            case 'pinOK':
                helper.checkPIN(component);
                break;
            case 'pullout':
                helper.pulloutCard(component);
                break;
            default:
                console.log("ERROR: Unknown button clicked");
        }
    },

    handleInputChange: function(component, event, helper) {
        let userInput = event.getParam("value");

        // If no input just show base exchange rate
        if(!userInput) {
            helper.showExRate(component);
            return;
        }

        // Amount to show in exchange rate field
        let inputAmount;

        let lastIndex = userInput.length - 1;
        let lastChar = userInput[lastIndex];

        // If input matches unsigned floating point number with 13-digits integer part,
        // 2 decimal deigits precision and doesn't start with multiple 0s it is correct...
        if(userInput.match(/^(\d{1,13}([.]\d{0,2})?|[.]\d{0,2})$/) && userInput !== '00') {
            inputAmount = parseFloat(userInput);

        // ... otherwise remove last inputted character and return
        } else {
            userInput = userInput.substring(0, lastIndex);
            event.getSource().set("v.value", userInput);

            return;
        }

        if(inputAmount) {
            helper.showExRate(component, inputAmount);
        }
    },

    handlePINKeydown: function(component, event, helper) {
        if(event.key === 'Enter') {
            helper.checkPIN(component);
        } else if (event.key === 'Escape') {
            helper.pulloutCard(component);
        }
    },

    handlePINInput: function (component, event, helper) {
        let pinInput = event.getParam("value");

        // PIN should not be more than 4 digits long
        if(pinInput.length >= 4) {
            pinInput = pinInput.substr(0, 4);
        }

        // PIN should contain only digits
        let lastIndex = pinInput.length - 1;
        if(!parseInt(pinInput[lastIndex])) {
            pinInput = pinInput.substring(0, lastIndex);
        }

        event.getSource().set("v.value", pinInput);
    }
})