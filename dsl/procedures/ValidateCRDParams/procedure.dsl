// This procedure.dsl was generated automatically
// === procedure_autogen starts ===
procedure 'ValidateCRDParams', description: '', {

    step 'validateCRDParams', {
        description = ''
        command = new File(pluginDir, "dsl/procedures/ValidateCRDParams/steps/validateCRDParams.pl").text
        shell = 'ec-perl'

        }
// === procedure_autogen ends, checksum: 6bac3f90bc9af21d6214a4d417797a46 ===
// Do not update the code above the line
// procedure properties declaration can be placed in here, like
// property 'property name', value: "value"
}