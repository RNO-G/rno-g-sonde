int makegpx(const char * rootfile, const char *gpxfile, const char * name = 0, const char * json_fragment = 0)
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



  t->GetEntry(0); 
  double start_time = tim; 
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

  if (json_fragment) 
  {
    printf("Writing json fragment to %s\n", json_fragment); 
    FILE * json = fopen(json_fragment,"w"); 
    fprintf(json,"  {\n"); 
    fprintf(json, "  \"filename\": \"%s\",\n", rootfile); 
    fprintf(json, "  \"name\": \"%s\",\n", name ?: rootfile); 
    fprintf(json, "  \"start_time\": %f,\n", start_time ); 
    fprintf(json, "  \"end_time\": %f,\n", tim ); 
    fprintf(json, "  \"end_lat\": %f,\n", lat ); 
    fprintf(json, "  \"end_lon\": %f,\n", lon ); 
    fprintf(json, "  \"end_alt\": %f\n", alt ); 
    fprintf(json,"  }\n"); 
    fclose(json); 
  }
  return 0; 
}



