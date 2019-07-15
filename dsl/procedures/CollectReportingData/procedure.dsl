// This procedure.dsl was generated automatically
// === procedure_autogen starts ===
procedure 'CollectReportingData', description: '', {

    step 'CollectReportingData', {
        description = ''
        command = new File(pluginDir, "dsl/procedures/CollectReportingData/steps/CollectReportingData.pl").text
        shell = 'ec-perl'

        }
// === procedure_autogen ends, checksum: e97d61dc14c8844b7581264edaff2627 ===
// Do not update the code above the line
// procedure properties declaration can be placed in here, like
// property 'property name', value: "value"
}