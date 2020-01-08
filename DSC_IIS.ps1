Configuration DSC_IIS
{
      Node "localhost"
      {
            WindowsFeature IIS
            {
                  Ensure = "Present"
                  Name = "Web-Server"
            }
      }
}
