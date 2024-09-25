public with sharing class ModeloLogoChecker {
    @AuraEnabled
    public static Map<String, Object> checkLogoMatch(Id modeloId) {
        Modelo__c modelo;
        Account marca;
        Boolean shouldUpdate  = false;
        Boolean logoUpdated = false;

        try {
            verifyPermissions(); // Check if the user has the necessary permissions to access the objects
            System.debug('Permissions checked');
            
            modelo = getModel(modeloId); // Get the 'Modelo' record with the provided ID
            System.debug('Model obtained: ' + modelo);

            marca = getBrand(modelo.Marca__c); // Get the 'Brand' associated with the 'Modelo'
            System.debug('Marca obtained: ' + marca);


            // Check if the logo needs to be updated
            shouldUpdate  = mustUpdateLogo(modelo, marca);
            System.debug('It should update: ' + shouldUpdate );
        } catch (Exception e) {
           // Capture any error and throw a custom exception to be handled in the Aura component
            System.debug('Logo verification error: ' + e.getMessage());
            throw new AuraHandledException('Error checking logo match: ' + e.getMessage());
        }

        // If the logo needs to be updated, calls the method to update the record
        if (shouldUpdate ) {
            updateLogo(modelo, marca, logoUpdated);
        }

        // Response to debug in console.log
        return buildAnswer(modelo, marca, shouldUpdate , logoUpdated);
    }

    // Update the logo URL field in the 'Model' record
    private static Boolean updateLogo(Modelo__c modelo, Account marca, Boolean logoUpdated) {
        String logoUrlMarca = (marca.Logo_Marca__c != null) ? extractContentBetweenWings(marca.Logo_Marca__c) : '';
        System.debug('Extracted logo: ' + logoUrlMarca);

        // Checks if the field can be updated and if the value has actually changed
        if (Schema.sObjectType.Modelo__c.fields.Logo_Marca_URL__c.isUpdateable()) {
            if (modelo.Logo_Marca_URL__c != logoUrlMarca) {
                System.debug('Updating the logo for the model: ' + modelo.Id);
                modelo.Logo_Marca_URL__c = logoUrlMarca;
                try {
                // Checks that the DML limit has not yet been reached
                    if (Limits.getDmlStatements() < Limits.getLimitDmlStatements()) {
                        update modelo; // Update only if the limit has not yet been reached
                        logoUpdated = true;
                        System.debug('Updated registration: ' + modelo.Id);
                    } else {
                        System.debug('DML limit already reached, update not possible.');
                    }
                } catch (DmlException e) {
                    throw new CustomException('Error updating Modelo__c: ' + e.getMessage());
                }
            } else {
                System.debug('No update necessary.');
            }
        } else {
            throw new CustomException('You do not have permission to update Modelo__c.');
        }

        return logoUpdated;
    }

   // Checks access permissions to objects
    private static void verifyPermissions() {
        if (!Schema.sObjectType.Modelo__c.isAccessible()) {
            throw new CustomException('You do not have permission to access Modelo__c.');
        }
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new CustomException('You do not have permission to access Account.');
        }
    }

    // Returns the 'Model' record by its ID
    private static Modelo__c getModel(Id modeloId) {
        try {
            return [SELECT Logo_Marca_URL__c, Marca__c FROM Modelo__c WHERE Id = :modeloId LIMIT 1];
        } catch (QueryException e) {
            throw new CustomException('Modelo__c not found: ' + e.getMessage());
        }
    }

     // Returns the 'Account' record (Brand) by ID and checking the Record Type
    private static Account getBrand(Id marcaId) {
        try {
            return [SELECT Logo_Marca__c, Name, Id FROM Account WHERE Id = :marcaId AND RecordTypeId = '012WU000002F3HNYA0' LIMIT 1];
        } catch (QueryException e) {
            throw new CustomException('Account not found or invalid Record Type.');
        }
    }

    // Checks if the model logo needs to be updated against the brand logo
    private static Boolean mustUpdateLogo(Modelo__c modelo, Account marca) {         
        // Verifica se a marca do modelo é a mesma e se o logo é diferente ou inexistente
        return marca.Id == modelo.Marca__c && (marca.Logo_Marca__c != modelo.Logo_Marca_URL__c || (modelo.Logo_Marca_URL__c == null && marca.Logo_Marca__c != null));
    }

    // Extracts the content in quotes from a Rich Text field
    private static String extractContentBetweenWings(String marcaLogoMarca) {
        if (marcaLogoMarca == null) {
            return null; 
        }

        Integer primeiroIndex = marcaLogoMarca.indexOf('"'); 
        Integer segundoIndex = marcaLogoMarca.indexOf('"', primeiroIndex + 1); 
       
        if (primeiroIndex != -1 && segundoIndex != -1) {
            // Extracts the content in quotes
            String conteudoExtraido = marcaLogoMarca.substring(primeiroIndex + 1, segundoIndex);

            // Replace “&amp;” with “&”
            return conteudoExtraido.replace('&amp;', '&');
        }

        return null; 
    }

    // Response to debug in console.log
    private static Map<String, Object> buildAnswer(Modelo__c modelo, Account marca, Boolean shouldUpdate, Boolean logoUpdated) {
        return new Map<String, Object> {
            'logosMatch' => shouldUpdate, // Indicates whether the logo needs to be updated
            'marcaIDAccount' => marca.Id, // ID of the brand (Account)
            'marcaLogoAccount' => marca.Logo_Marca__c, // Brand logo (Rich Text field)
            'marcaNomeAccount' => marca.Name, // Brand name
            'modeloMarcaNome' => modelo.Marca__c, // Reference to the brand in the model
            'modeloLogo_Marca_URL__c' => modelo.Logo_Marca_URL__c, // Current logo URL in the model
            'logoUpdated' => logoUpdated, // Indicates if the logo has been updated
            'modeloId' => modelo.Id // ID of the model
        };
    }    

    public class CustomException extends Exception {}
}