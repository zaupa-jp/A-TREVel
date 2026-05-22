#include <iostream>
#include <math.h>
#include "constant.h"
#include <stdio.h>
#include <stdlib.h>
#include <string>

using namespace std;

void xyz2llh(double x, double y, double z, double *lat, double *lon, double *h);
void llh2xyz(double lat, double lon,double h, double *x, double *y, double *z);
void xyz2local(double Xest,double Yest,double Zest, double x,double y,double z, double &e,double &n,double &u);
void dist_llh_llh(double lat1, double lon1, double h1, double lat2, double lon2, double h2, double *dist);
void interpolaVemos2009Dist(double Xin, double Yin, double Zin, double latIn, double lonIn, double hIn, double *VxOut, double *VyOut, double *VzOut);

int main(int argc, char *argv[])
{

    FILE *arq, *arq2, *arqTrevel;
    double Xin=0.0, Yin=0.0, Zin=0.0, Xout=0.0, Yout=0.0, Zout=0.0,
            AnoIn=0.0, MesIn=0.0, DiaIn=0.0, AnoOut=0.0, MesOut=0.0, DiaOut=0.0,
            Tx=0.0, Ty=0.0, Tz=0.0, D=0.0, Rx=0.0, Ry=0.0, Rz=0.0,
            STx=0.0, STy=0.0, STz=0.0, SD=0.0, SRx=0.0, SRy=0.0, SRz=0.0,
            EpochIn=0.0, EpochOut=0.0, LatOut=0.0, LonOut=0.0, AltOut=0.0, LatSec, LonSec,
            LatIn, LonIn, hIn, Lat, Lon, Vlat, Vlon, Vx, Vy, Vz, VlatOut, VlonOut, VxOut, VyOut, VzOut,
            Dist, MinDist=pow(10,8), LatXyz, LonXyz, hXyz;

    int LatGraus, LonGraus, LatMin, LonMin;
    string DatumIn, DatumOut, CoordType;

    //argv[1]="llh";
    //argv[2]="-25.2";
    //argv[3]="-55.2";
    //argv[4]="400";
    //argv[5]="2000";
    //argv[6]="1";
    //argv[7]="10";
    //argv[8]="2000";
    //argv[9]="1";
    //argv[10]="10";
    //argv[11]="TRF08";
    //argv[12]="SIR00";

    CoordType=argv[1];

   if(CoordType == "llh"){
    LatIn=atof(argv[2]);  LonIn=atof(argv[3]);  hIn=atof(argv[4]);
    AnoIn=atof(argv[5]); MesIn=atof(argv[6]);   DiaIn=atof(argv[7]);
    AnoOut=atof(argv[8]); MesOut=atof(argv[9]);   DiaOut=atof(argv[10]);
    DatumIn=argv[11];    DatumOut=argv[12];
    llh2xyz(LatIn*PI/180, LonIn*PI/180, hIn, &Xin, &Yin, &Zin);
   }

   else if(CoordType == "xyz"){
    Xin=atof(argv[2]);  Yin=atof(argv[3]);  Zin=atof(argv[4]);
    AnoIn=atof(argv[5]); MesIn=atof(argv[6]);   DiaIn=atof(argv[7]);
    AnoOut=atof(argv[8]); MesOut=atof(argv[9]);   DiaOut=atof(argv[10]);
    DatumIn=argv[11];    DatumOut=argv[12];
    xyz2llh(Xin, Yin, Zin, &LatXyz, &LonXyz, &hXyz);
    LatIn=LatXyz*180/PI;
    LonIn=LonXyz*180/PI;
    hIn=hXyz;
   }

        VxOut=0.0;  VyOut=0.0;  VzOut=0.0;

        interpolaVemos2009Dist(Xin, Yin, Zin, LatIn*PI/180, LonIn*PI/180, 0.0, &VxOut, &VyOut, &VzOut);

        EpochIn=AnoIn+(MesIn/12.0)+(DiaIn/(365.0));
        EpochOut=AnoOut+(MesOut/12.0)+(DiaOut/(365.0));

        if(DatumIn=="TRF08" && DatumOut=="TRF05"){
            Tx=-2.0/1000.0; Ty=-0.9/1000.0;Tz=-4.7/1000.0;D=0.94*pow(10, -9);
            STx=0.3/1000.0;STy=0.0; STz=0.0;SD=0.0;
        }

        else if(DatumIn=="TRF08" && DatumOut=="SIR00"){
            Tx=-1.9/1000.0; Ty=-1.7/1000.0;Tz=-10.5/1000.0;D=1.34*pow(10, -9);
            STx=0.1/1000.0;STy=0.1/1000.0; STz=-1.8/1000.0;SD=0.08*pow(10, -9);
        }

        else if(DatumIn=="TRF05" && DatumOut=="TRF08"){
            Tx=2.0/1000.0; Ty=0.9/1000.0;Tz=4.7/1000.0;D=-0.94*pow(10, -9);
            STx=-0.3/1000.0;STy=0.0; STz=0.0;SD=0.0;
        }

        else if(DatumIn=="TRF05" && DatumOut=="SIR00"){
            Tx=0.1/1000.0; Ty=-0.8/1000.0;Tz=-5.8/1000.0;D=0.4*pow(10, -9);
            STx=-0.2/1000.0;STy=0.1/1000.0; STz=-1.8/1000.0;SD=0.08*pow(10, -9);
        }

        else if(DatumIn=="SIR00" && DatumOut=="TRF08"){
            Tx=1.9/1000.0; Ty=1.7/1000.0;Tz=10.5/1000.0;D=-1.34*pow(10, -9);
            STx=-0.1/1000.0;STy=-0.1/1000.0; STz=1.8/1000.0;SD=-0.08*pow(10, -9);
        }

        else if(DatumIn=="SIR00" && DatumOut=="TRF05"){
            Tx=-0.1/1000.0; Ty=0.8/1000.0;Tz=5.8/1000.0;D=-0.4*pow(10, -9);
            STx=0.2/1000.0;STy=-0.1/1000.0; STz=1.8/1000.0;SD=-0.08*pow(10, -9);
        }

        Xout = Tx + ((Xin + VxOut*(EpochOut-EpochIn))*(1+D)*(1+Rx));
        Xout += (EpochOut-EpochIn)*(STx+(((1+SD)*SRx)+(SD*Rx))*Xin);

        Yout = Ty + ((Yin + VyOut*(EpochOut-EpochIn))*(1+D)*(1+Ry));
        Yout += (EpochOut-EpochIn)*(STy+(((1+SD)*SRy)+(SD*Ry))*Yin);

        Zout = Tz + ((Zin + VzOut*(EpochOut-EpochIn))*(1+D)*(1+Rz));
        Zout += (EpochOut-EpochIn)*(STz+(((1+SD)*SRz)+(SD*Rz))*Zin);

        xyz2llh(Xout, Yout, Zout, &LatOut, &LonOut, &AltOut);

        LatGraus=LatOut*180/PI;
        LatMin=fabs(LatGraus-LatOut*180/PI)*60;
        LatSec=fabs(LatMin-(LatGraus-LatOut*180/PI)*60)*60;

        LonGraus=LonOut*180/PI;
        LonMin=fabs(LonGraus-LonOut*180/PI)*60;
        LonSec=fabs(LonMin-(LonGraus-LonOut*180/PI)*60)*60;

//fclose(arq);

    printf("%d\n", LatGraus);
    printf("%d\n", LatMin);
    printf("%.4lf\n", LatSec);

    printf("%d\n", LonGraus);
    printf("%d\n", LonMin);
    printf("%.4lf\n", LonSec);

    printf("%.2lf\n", AltOut);

    printf("%.5lf\n", Xout);
    printf("%.5lf\n", Yout);
    printf("%.5lf\n", Zout);

    printf("%.5lf\n", VxOut);
    printf("%.5lf\n", VyOut);
    printf("%.5lf\n", VzOut);

    cout << DatumOut << endl;
    printf("%.0lf\n", AnoOut);
if(MesOut<10){
    printf("0%.0lf\n", MesOut);
}
else{
    printf("%.0lf\n", MesOut);
}
    printf("%.0lf\n", DiaOut);

    printf("%lf\n", Tx);
    printf("%lf\n", Ty);
    printf("%lf\n", Tz);

}

void interpolaVemos2009Dist(double Xin, double Yin, double Zin, double latIn, double lonIn, double hIn, double *VxOut, double *VyOut, double *VzOut)
{
    FILE *arq, *arqOut;
    double Lat, Lon, Vlat, Vlon, Vx, Vy, Vz, MinDist=1000000, Dist;
    double LatTop, LatBot, LonLeft, LonRight, Lat1, Lat2, Lat3, Lat4, Lon1, Lon2, Lon3, Lon4,
            Vlat1, Vlat2, Vlat3, Vlat4, Vlon1, Vlon2, Vlon3, Vlon4, VlatTop, VlonTop, VlatBot, VlonBot;
    double Vx1=0.0, Vx2=0.0, Vx3=0.0, Vx4=0.0, Vy1=0.0, Vy2=0.0, Vy3=0.0, Vy4=0.0, Vz1=0.0, Vz2=0.0, Vz3=0.0, Vz4=0.0;
    double X1, X2, X3, X4, Y1, Y2, Y3, Y4, Z1, Z2, Z3, Z4, Dist1=pow(10,10), Dist2=pow(10,10), Dist3=pow(10,10), Dist4=pow(10,10);
    double LatIn, LonIn;

    ///////////////////////////////////////   X1           X2
    ///////////////////////////////////////   X3           X4

    arq=fopen("gridvms.TXT", "r");

    LatIn=latIn*180/PI;
    LonIn=lonIn*180/PI;

    if(latIn>0.0){
    LatTop=ceil(latIn*180/PI);
    LatBot=LatTop-1;
    }

    else if(latIn<0.0){
    LatTop=ceil(latIn*180/PI);
    LatBot=LatTop-1;
    }

    if(lonIn<0.0){
        LonRight=ceil(lonIn*180/PI);
        LonLeft=LonRight-1;
    }

    Lat1=Lat2=LatTop;
    Lat3=Lat4=LatBot;

    Lon1=Lon3=LonLeft;
    Lon2=Lon4=LonRight;

    while (!feof(arq)){

        fscanf(arq, "%lf%lf%lf%lf%lf%lf%lf", &Lat, &Lon, &Vlat, &Vlon, &Vx, &Vy, &Vz);
       // fprintf(arqOut, "%lf\t%lf\t%lf\n", Lon, Lat, sqrt(pow(Vx,2)+pow(Vy,2)+pow(Vz,2)));

        if(fabs(Lat-Lat1) < 0.00000001 && fabs(Lon-Lon1) < 0.00000001 ){
            Vx1=Vx;
            Vy1=Vy;
            Vz1=Vz;
            dist_llh_llh(latIn, lonIn, 0.0, Lat1*PI/180, Lon1*PI/180, 0.0, &Dist1);
          //  Dist1+= sqrt(pow(0.001, 2)+pow(0.0015, 2));
            //Dist1=pow(Dist1, 2);
        }
        else if(fabs(Lat-Lat2) < 0.00001 && fabs(Lon-Lon2) < 0.00001){
            Vx2=Vx;
            Vy2=Vy;
            Vz2=Vz;
            dist_llh_llh(latIn, lonIn, 0.0, Lat2*PI/180, Lon2*PI/180, 0.0, &Dist2);
          //  Dist2+= sqrt(pow(0.001, 2)+pow(0.0015, 2));
            //Dist2=pow(Dist2, 2);
        }

        else if(fabs(Lat-Lat3) < 0.00001 && fabs(Lon-Lon3) < 0.00001){
            Vx3=Vx;
            Vy3=Vy;
            Vz3=Vz;
            dist_llh_llh(latIn, lonIn, 0.0, Lat3*PI/180, Lon3*PI/180, 0.0, &Dist3);
           // Dist3+= sqrt(pow(0.001, 2)+pow(0.0015, 2));
            //Dist3=pow(Dist3, 2);
        }
        else if(fabs(Lat-Lat4) < 0.00001 && fabs(Lon-Lon4) < 0.00001){
            Vx4=Vx;
            Vy4=Vy;
            Vz4=Vz;
            dist_llh_llh(latIn, lonIn, 0.0, Lat4*PI/180, Lon4*PI/180, 0.0, &Dist4);
            //Dist4+= sqrt(pow(0.001, 2)+pow(0.0015, 2));
            //Dist4=pow(Dist4, 2);
        }

    }
    fclose(arq);

    double  Sum1, Sum2, Sum3, Sum4,
            DivX1, DivX2, DivX3, DivX4,
            DivY1, DivY2, DivY3, DivY4,
            DivZ1, DivZ2, DivZ3, DivZ4;

    if(Vx1==0.0 || Dist1==0.0){  DivX1=0.0; Sum1=0.0;    }
    else{    DivX1=(Vx1/Dist1);  Sum1=1.0/Dist1;         }

    if(Vx2==0.0 || Dist2==0.0){  DivX2=0.0; Sum2=0.0;    }
    else{    DivX2=(Vx2/Dist2);  Sum2=1.0/Dist2;         }

    if(Vx3==0.0 || Dist3==0.0){  DivX3=0.0; Sum3=0.0;    }
    else{    DivX3=(Vx3/Dist3);  Sum3=1.0/Dist3;         }

    if(Vx4==0.0 || Dist4==0.0){  DivX4=0.0; Sum4=0.0;    }
    else{    DivX4=(Vx4/Dist4);  Sum4=1.0/Dist4;         }

    if(Vy1==0.0 || Dist1==0.0){  DivY1=0.0; Sum1=0.0;    }
    else{    DivY1=(Vy1/Dist1);  Sum1=1.0/Dist1;         }

    if(Vy2==0.0 || Dist2==0.0){  DivY2=0.0; Sum2=0.0;    }
    else{    DivY2=(Vy2/Dist2);  Sum2=1.0/Dist2;         }

    if(Vy3==0.0 || Dist3==0.0){  DivY3=0.0; Sum3=0.0;    }
    else{    DivY3=(Vy3/Dist3);  Sum3=1.0/Dist3;         }

    if(Vy4==0.0 || Dist4==0.0){  DivY4=0.0; Sum4=0.0;    }
    else{    DivY4=(Vy4/Dist4);  Sum4=1.0/Dist4;         }

    if(Vz1==0.0 || Dist1==0.0){  DivZ1=0.0; Sum1=0.0;    }
    else{    DivZ1=(Vz1/Dist1);  Sum1=1.0/Dist1;         }

    if(Vz2==0.0 || Dist2==0.0){  DivZ2=0.0; Sum2=0.0;    }
    else{    DivZ2=(Vz2/Dist2);  Sum2=1.0/Dist2;         }

    if(Vz3==0.0 || Dist3==0.0){  DivZ3=0.0; Sum3=0.0;    }
    else{    DivZ3=(Vz3/Dist3);  Sum3=1.0/Dist3;         }

    if(Vz4==0.0 || Dist4==0.0){  DivZ4=0.0; Sum4=0.0;    }
    else{    DivZ4=(Vz4/Dist4);  Sum4=1.0/Dist4;         }

    if((DivX1+DivX2+DivX3+DivX4)==0.0 || (Sum1+Sum2+Sum3+Sum4)==0.0){   *VxOut=0.0;    }
    else{  *VxOut=(DivX1+DivX2+DivX3+DivX4)/(Sum1+Sum2+Sum3+Sum4);   }

    if(DivY1+DivY2+DivY3+DivY4==0.0 || Sum1+Sum2+Sum3+Sum4==0.0){   *VyOut=0.0;    }
    else{  *VyOut=(DivY1+DivY2+DivY3+DivY4)/(Sum1+Sum2+Sum3+Sum4);   }

    if(DivZ1+DivZ2+DivZ3+DivZ4==0.0 || Sum1+Sum2+Sum3+Sum4==0.0){   *VzOut=0.0;    }
    else{  *VzOut=(DivZ1+DivZ2+DivZ3+DivZ4)/(Sum1+Sum2+Sum3+Sum4);   }

//    cout << Lat1 << "\t" << Lon1 << "\t" << Vx1 << "\t" << Vy1 << "\t" << Vz1 << "\t" << endl;
//    cout << Lat2 << "\t" << Lon2 << "\t" << Vx2 << "\t" << Vy2 << "\t" << Vz2 << "\t" << endl;
//    cout << Lat3 << "\t" << Lon3 << "\t" << Vx3 << "\t" << Vy3 << "\t" << Vz3 << "\t" << endl;
//    cout << Lat4 << "\t" << Lon4 << "\t" << Vx4 << "\t" << Vy4 << "\t" << Vz4 << "\t" << endl;
//    cout << *VxOut << "\t" << *VyOut <<"\t" << *VzOut << endl;
}

void llh2xyz(double lat, double lon,double h, double *x, double *y, double *z)
{
    double N;

    N = eixo_a / sqrt(1.0-eccentricity2 * sin(lat)*sin(lat) );

    *x = (N+h) * cos(lat) * cos(lon);
    *y = (N+h) * cos(lat) * sin(lon);
    *z = (N*(1.0-eccentricity2) + h )* sin(lat);
}


void xyz2llh(double x, double y, double z, double *lat, double *lon, double *h)
{
  int iter;
  double delta,tmp,N,lat1,lat_prev,htmp;

  iter = 0;
  delta = 1.0;

  if ( sqrt( x*x + y*y) < 1.0e-10 ) {
    cout << "ERROR: attempting square root of zero in xyz2llh " << endl;
    exit(0);
  }

  lat_prev = atan( z / sqrt( x*x + y*y) ) ;
  while ( fabs(delta) > 1.0e-12 ) {
    iter++;
    if ( iter > 20 ) {
      printf("no convergence in xyz2llh\n");
      exit(0);
    }

    N = eixo_a / sqrt(1.0-eccentricity2 * sin(lat_prev)*sin(lat_prev) );

    htmp = sqrt(x*x + y*y) / cos(lat_prev) - N;
    tmp = 1.0 - eccentricity2 * (N / ( N + htmp));
    lat1 = atan(z / sqrt( x*x + y*y ) / tmp );
    delta = lat_prev - lat1;
    lat_prev = lat1;
  }
  *lat = lat1;
  *lon = atan2(y,x);
  *h   = htmp;
}

void xyz2local(double Xest,double Yest,double Zest, double x,double y,double z, double &e,double &n,double &u)

{
    double dx, dy, dz, lat, lon, h;

    dx = x - Xest ;
    dy = y - Yest ;
    dz = z - Zest ;

    xyz2llh(Xest, Yest, Zest, &lat, &lon, &h);

    n = (-(sin(lat)*cos(lon))*dx) - ((sin(lat)*sin(lon))*dy) + (cos(lat)*dz);
    e = ((-sin(lon)*dx)+(cos(lon))*dy);
    u = (((cos(lat)*cos(lon)))*dx) + ((cos(lat)*sin(lon))*dy) + (sin(lat)*dz);
}

void dist_llh_llh(double lat1, double lon1, double h1, double lat2, double lon2, double h2, double *dist)
{
    double X, Y, Z, x, y, z;

    llh2xyz(lat1, lon1, h1, &X, &Y, &Z);
    llh2xyz(lat2, lon2, h2, &x, &y, &z);

    *dist = sqrt(pow((X - x),2)+ pow((Y - y),2)+ pow((Z - z),2.0));

}

