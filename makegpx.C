int makegpx(const char * rootfile, const char *gpxfile, const char * name = 0)
{

  TFile f(rootfile); 

  TTree *t = (TTree*) f.Get("GpsResults"); 

  if (!t) 
  {
    std::cerr << "Can't find GpsResults in " << rootfile << std::endl; 
    return 1; 
  }

  double lat, lon,alt,tim; 
  t->SetBranchAddress("Wgs84Latitude",&lat);
  t->SetBranchAddress("Wgs84Longitude",&lon);
  t->SetBranchAddress("Wgs84Altitude",&alt);
  t->SetBranchAddress("DataSrvTime",&tim);
  FILE * gpx = fopen(gpxfile,"w"); 

  if (!gpx) 
  {
    std::cerr << "Couldn't open " << gpxfile << " for writing " << std::endl; 
    return 1; 
  }


  fprintf(gpx,"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n"); 
  fprintf(gpx,"<gpx xmlns=\"http://www.topografix.com/GPX/1/1\">\n"); 

  fprintf(gpx,"  <trk>\n");
  fprintf(gpx,"    <name>%s</name>\n", name ?: rootfile);
  fprintf(gpx,"    <trkseg>\n"); 



  for (int i = 0; i < t->GetEntries(); i++)
  {
    t->GetEntry(i); 
    time_t tt = tim; 
    struct tm * the_tm = gmtime(&tt); 
    fprintf(gpx,"       <trkpt lat=\"%f\" lon=\"%f\">\n", lat, lon); 
    fprintf(gpx,"         <ele>%f</ele>\n",alt); 
    fprintf(gpx,"         <time>%04d-%02d-%02dT%02d:%02d:%02dZ</time>\n", the_tm->tm_year+1900, the_tm->tm_mon+1, the_tm->tm_mday, the_tm->tm_hour, the_tm->tm_min, the_tm->tm_sec); 
    fprintf(gpx,"       </trkpt>\n"); 
  }

  fprintf(gpx,"    </trkseg>\n"); 
  fprintf(gpx,"  </trk>\n"); 
  fprintf(gpx,"</gpx>\n"); 
  fclose(gpx); 
  return 0; 
}



