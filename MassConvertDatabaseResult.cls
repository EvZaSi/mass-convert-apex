public class MassConvertDatabaseResult {
    public Database.LeadConvertResult conversionresult;
    public String leadInfo;
    public String resultMessage;
    
    public MassConvertDatabaseResult(Database.LeadConvertResult newconversionresult,String newleadinfo){
        this.conversionresult = newconversionresult;
        this.leadinfo = newleadinfo;
        if(this.conversionresult.isSuccess()==true){
            this.resultMessage = 'Converted Succesfully';
        }else{
            List<Database.Error> errorlist = conversionresult.getErrors();
            for(Integer iterate_error = 0;iterate_error<errorlist.size();iterate_error++){
                if(iterate_error == errorlist.size()-1){
                    this.resultMessage = this.resultMessage + errorlist[iterate_error];
                }else{
                    this.resultMessage = this.resultMessage + errorlist[iterate_error] + ',';
                }
                
            }
        }conversionresult = null;
    }
    public String getresultMessage(){
        return this.resultMessage;
    }
    public String getleadInfo(){
        return this.leadInfo;
    }

}