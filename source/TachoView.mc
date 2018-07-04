//! Copyright (C) 2018 Tomasz Korzec <tom@shmo.de>
//!
//! This program is free software: you can redistribute it and/or modify it
//! under the terms of the GNU General Public License as published by the Free
//! Software Foundation, either version 3 of the License, or (at your option)
//! any later version.
//!
//! This program is distributed in the hope that it will be useful, but WITHOUT
//! ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//! FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//! more details.
//!
//! You should have received a copy of the GNU General Public License along
//! with this program. If not, see <http://www.gnu.org/licenses/>.


using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

var bg = false;

class TachoView extends Ui.DataField {

    hidden var dx;
    hidden var dy;
    hidden var hr_bar;
    hidden var el_bar;
    hidden var cd_bar;
    hidden var pw_bar;
    hidden var heading=0;
    hidden var ed=0;
    hidden var speed=0;
    hidden var cad_stps = [40, 50, 60, 70, 75, 80, 83, 86, 89, 92, 97, 102, 110, 120, 130, 140];
    hidden var grd_stps = [-30,-26,-22,-18,-14,-10,-6,-2, 2, 6, 10, 14, 18, 22, 26, 30];
    hidden var pzo      = [Application.Properties.getValue("pzone0"), Application.Properties.getValue("pzone1"), Application.Properties.getValue("pzone2"),
                           Application.Properties.getValue("pzone3"), Application.Properties.getValue("pzone4"), Application.Properties.getValue("pzone5")];
    hidden var avcd = 0;
    hidden var avhr = 0;
    hidden var Ncd  = 0;
    hidden var Nhr  = 0;
    hidden var cadence = 0;
    hidden var heartrate = 0;
    hidden var altitude = 0;
    hidden var av_cadence = 0;
    hidden var av_power = 0.0;
    hidden var av_heartrate = 0;
    hidden var power = 0;
    hidden var avpwr = 0;
    hidden var Npwr = 0;
    hidden var Npwr2= 0;
    hidden var ascent = 0;
    hidden var descent= 0;
    hidden var dist_old = null;
    hidden var alt_old = null;
    hidden var speed_old = null;
    hidden var time_old = null;
    hidden var grade = 0;
    hidden var tot_time = 0;
    hidden var tot_dist = 0;
    hidden var head_str = ["north","north-west","west","south-west","south","south-east","east","north-east"];
    hidden var head_int = 0;
    hidden var rho = 1.2754; // air density in kg/m^3 under standard conditions
    var Crr = Application.Properties.getValue("Crr"); // rolling resistance coefficient
    var CdA = Application.Properties.getValue("CdA");   // drag coefficient * frontal area in m^2
    var m = Application.Properties.getValue("m");     // mass rider+bike in kg

    function initialize()
    {
       DataField.initialize();
    }

    (:ed520)
    function onLayout(dc)
    {
       // hard coded for devices with 200x265
       dx=dc.getWidth();
       dy=dc.getHeight();
       var pal = [0x00008f,0x0000cf,0x0010ff,0x0050ff,0x008fff,0x00cfff,0x10ffef,0x50ffaf,
                  0x8fff70,0xcfff30,0xffef00,0xffaf00,0xff7000,0xff3000,0xef0000,0xaf0000];
       cd_bar = new superbar(40, dy/2+7,   dx-80,30,pal);
       el_bar = new superbar(40, dy/2+69,  dx-80,30,pal);
       pal = [0xd0d0d0, 0xa5a5a5, 0x73b1da, 0x7dbf62, 0xea6337, 0xec412f];
       hr_bar = new superbar(40, dy/2+38,  dx-80,30,pal);
       pal.add(0xff0000);
       pw_bar = new superbar(40, dy/2+100, dx-80,30,pal);
       return true;
    }

    function comp_power(y,v,dx, dy, dv, dt)
    {
       // compute virtual power
       // y altitude in m
       // v velocity in m/s
       // dx distance change in m
       // dy altitude change in m
       // dv velocity change in m/s
       // dt elapsed time in s
       var P = 0;

       var alpha = 0.0;

       alpha = Math.atan(dy/Math.sqrt(dx*dx-dy*dy));  // slope angle

       // rolling resistance
       P += Crr * m*9.81*Math.cos(alpha) * v;

       // air drag
       P += 0.5 * rho * v*v*v * CdA;

       // gravity
       P += m * 9.81 * Math.sin(alpha) * v;

       // acceleration
       P += m * (dv/dt) * v;

       // missing: change in rotational energy of the wheels

       if ( P<0 )
       {
          P = 0.0;
       }
       if (P>3000)
       {
          P = 3000;
       }
       return P;
    }

    function compute(info)
    {
       var col = 0;
       var i;
       if( info != null)
       {
          if(dist_old==null && info.elapsedDistance != null)
          {
             dist_old = info.elapsedDistance;
          }
          if(alt_old == null && info.altitude != null)
          {
             alt_old = info.altitude;
          }
          if(speed_old == null && info.currentSpeed != null)
          {
             speed_old = info.currentSpeed;
          }
          if(time_old == null && info.elapsedTime != null)
          {
             time_old = info.elapsedTime;
          }

          if(info.currentSpeed != null)
          {
             speed = info.currentSpeed*3.6; // in km/h
          }
          if(info.currentHeading != null)
          {
             heading = info.currentHeading;
          }
          if (info.currentHeartRate != null)
          {
             heartrate = info.currentHeartRate;
          }
          if (info.altitude != null)
          {
             altitude = Math.round(info.altitude).toNumber();
          }
          if (info.averageCadence != null)
          {
             av_cadence = info.averageCadence;
          }
          if (info.averageHeartRate != null)
          {
             av_heartrate = info.averageHeartRate;
          }
          if (info.totalAscent != null)
          {
             ascent = Math.round(info.totalAscent).toNumber();
          }
          if (info.totalDescent != null)
          {
             descent = Math.round(info.totalDescent).toNumber();
          }
          if (info.elapsedTime != null)
          {
             var sec = info.elapsedTime/1000;
             tot_time = Lang.format("$1$:$2$:$3$",[sec/3600, (sec % 3600)/60, sec % 60]);
          }

          if (info.currentHeading != null)
          {
             head_int = Math.round(8-info.currentHeading*(1.27323954474)).toNumber() % 8;
          }

          if(info.elapsedDistance!=null)
          {
             tot_dist = Math.round(info.elapsedDistance*0.001).toNumber();

             if(info.elapsedDistance < dist_old)
             {
                // new activity, reset bars
                cd_bar.reset();
                hr_bar.reset();
                pw_bar.reset();
                el_bar.reset();
                ed=0;
                av_power = 0;
                Npwr2 = 0;
             }
             // add to 10m averages
             if(info.currentCadence != null)
             {
                cadence = info.currentCadence;
                avcd += cadence;
                Ncd++;
             }

             // power with powermeter (10m average)
             if(info.currentPower != null)
             {
                power = info.currentPower;
                avpwr += power;
                Npwr++;
                av_power = info.averagePower;
             }

             if(info.elapsedDistance>ed+10)
             {
                ed=info.elapsedDistance;

                if(Ncd>0)
                {
                   avcd = avcd/Ncd;
                }


                if(info.currentPower != null)
                {
                   if (Npwr>0)
                   {
                      avpwr = avpwr/Npwr;
                   }
                }else
                {
                   // compute 10m virtual power
                   if(alt_old != null && dist_old != null && dist_old != info.elapsedDistance && speed_old != null && time_old != null)
                   {
                      avpwr = comp_power(info.altitude, info.currentSpeed, info.elapsedDistance-dist_old, info.altitude-alt_old, info.currentSpeed-speed_old, (info.elapsedTime-time_old)*0.001);
                      power = avpwr;
                   }
                   // add value to average power estimate
                   av_power = (Npwr2*av_power+power) / (Npwr2+1.0);
                   Npwr2++;
                }

                // cadence
                col=0;
                for(i=0; i<15; i++)
                {
                   if(avcd>cad_stps[i])
                   {
                      col++;
                   }
                }
                //System.println(avcd+" "+col);
                cd_bar.addval(avcd,col);
                avcd=0;
                Ncd =0;

                // heart rate
                if (info.currentHeartRate != null)
                {
                   var zo = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_BIKING);

                   if(info.currentHeartRate > zo[0])
                   {
                      col=1;
                   }
                   if(info.currentHeartRate > zo[1])
                   {
                      col=2;
                   }
                   if(info.currentHeartRate > zo[2])
                   {
                      col=3;
                   }
                   if(info.currentHeartRate > zo[3])
                   {
                      col=4;
                   }
                   if(info.currentHeartRate > zo[4])
                   {
                      col=5;
                   }
                   hr_bar.addval(info.currentHeartRate,col);
                }
                // elevation
                if(alt_old != null && dist_old != null && dist_old != info.elapsedDistance)
                {
                   grade = (info.altitude-alt_old) / Math.sqrt((info.elapsedDistance-dist_old)*(info.elapsedDistance-dist_old)-(info.altitude-alt_old)*(info.altitude-alt_old))*100;
                }
                col=0;
                for(i=0; i<15; i++)
                {
                   if(grade>grd_stps[i])
                   {
                      col++;
                   }
                }
                if(info.altitude != null)
                {
                   el_bar.addval(info.altitude,col);
                }

                // power
                col = 0; // active recovery
                if (avpwr != null)
                {
                   if(avpwr > pzo[0])
                   {
                      col=1; // endurance
                   }
                   if(avpwr > pzo[1])
                   {
                      col=2; // tempo
                   }
                   if(avpwr > pzo[2])
                   {
                      col=3; // lactate threshold
                   }
                   if(avpwr > pzo[3])
                   {
                      col=4; // VO2max
                   }
                   if(avpwr > pzo[4])
                   {
                      col=5; // anaerobic capacity
                   }
                   if(avpwr > pzo[5])
                   {
                      col=6; // neuromuscular power
                   }
                   pw_bar.addval(avpwr,col);
                   avpwr=0;
                   Npwr=0;
                }


                alt_old   = info.altitude;
                dist_old  = info.elapsedDistance;
                speed_old = info.currentSpeed;
                time_old = info.elapsedTime;
             }
          }
       }
    }

    function setCol(dc,col1,col2)
    {
       if(bg)
       {
          dc.setColor(col1,Gfx.COLOR_TRANSPARENT);
       }else
       {
          dc.setColor(col2,Gfx.COLOR_TRANSPARENT);
       }
    }

    function circline(dc,xc,yc,r1,r2,deg)
    {
       dc.drawLine(Math.round(xc-r1*Math.cos(deg*0.01745329251)).toNumber(), Math.round(yc-r1*Math.sin(deg*0.01745329251)).toNumber(),
                   Math.round(xc-r2*Math.cos(deg*0.01745329251)).toNumber(), Math.round(yc-r2*Math.sin(deg*0.01745329251)).toNumber());
    }

    function tacho(dc,xc,yl,r)
    {
       var i;
       // colorful speed indicator
       dc.setPenWidth(2);
       for(i=0; i<speed && i<=80; i+=0.2)
       {
          dc.setColor( ((Math.round(i*3.2).toNumber() <<16) & 0xff0000) + 0x00ff00-((Math.round(i*3.2).toNumber()<<8) & 0x00ff00) ,Gfx.COLOR_BLACK);
          circline(dc,xc,yl,r-9,r-1,i*2.25);
       }

       // tachoscheibe
       setCol(dc,Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);

       dc.setPenWidth(2);
       dc.drawArc(xc, yl, r, Gfx.ARC_COUNTER_CLOCKWISE, 0, 180);
       dc.drawArc(xc, yl, r-10, Gfx.ARC_COUNTER_CLOCKWISE, 0, 180);

       for(i=0; i<90; i+=10)
       {
          circline(dc,xc,yl,r-14,r,i*2.25);
          dc.drawText((xc-(r-23)*Math.cos(i*2.25*0.01745329251)).toNumber(), (yl-(r-23)*Math.sin(i*2.25*0.01745329251)).toNumber()-5,
                       Gfx.FONT_SMALL, i, Gfx.TEXT_JUSTIFY_CENTER);
       }

       // average + max
       var info = Toybox.Activity.getActivityInfo();
       var sp;
       if((info != null) && (info.averageSpeed !=null))
       {
          dc.setColor(0x3030d0, Gfx.COLOR_BLACK);
          sp = info.averageSpeed*3.6;
          if (sp>80.0)
          {
             sp=80.0;
          }
          circline(dc,xc,yl,r-10,r,sp*2.25);
          dc.fillCircle((xc-(r+3)*Math.cos(sp*2.25*0.01745329251)).toNumber(), (yl-(r+3)*Math.sin(sp*2.25*0.01745329251)).toNumber(),3);
       }
       if((info != null) && (info.maxSpeed !=null))
       {
          dc.setColor(0x8030a0, Gfx.COLOR_BLACK);
          sp = info.maxSpeed*3.6;
          if (sp>80.0)
          {
             sp=80.0;
          }
          circline(dc,xc,yl,r-10,r,sp*2.25);
          dc.fillCircle((xc-(r+3)*Math.cos(sp*2.25*0.01745329251)).toNumber(), (yl-(r+3)*Math.sin(sp*2.25*0.01745329251)).toNumber(),3);
       }


       // speed in grosser schrift
       setCol(dc,Gfx.COLOR_LT_GRAY,Gfx.COLOR_DK_GRAY);
       dc.drawText(xc,yl-r/2+1,Gfx.FONT_XTINY, "km/h",Gfx.TEXT_JUSTIFY_CENTER);
       setCol(dc,Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);
       dc.drawText(xc,yl-r/3+1,Gfx.FONT_LARGE, Math.round(speed).toNumber(),Gfx.TEXT_JUSTIFY_CENTER);
       dc.setPenWidth(1);
    }

    function header(dc)
    {
       var info = Activity.getActivityInfo();
       setCol(dc,Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);
       dc.drawLine(0,20,dx,20);
       dc.setClip(0,0,dx,20);

       dc.drawText(20,9,Gfx.FONT_XTINY,Math.round(System.getSystemStats().battery).toNumber()+ " %",Gfx.TEXT_JUSTIFY_CENTER);
       var today = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
       var clockString = Lang.format("$1$:$2$:$3$",[today.hour, today.min, today.sec]);
       dc.drawText(dx/2,0,Gfx.FONT_MEDIUM, clockString, Gfx.TEXT_JUSTIFY_CENTER);
       if(info != null && info.currentLocationAccuracy != null)
       {
          dc.drawText(dx-20,9,Gfx.FONT_XTINY,info.currentLocationAccuracy*25+" %",Gfx.TEXT_JUSTIFY_CENTER);
       }

       setCol(dc,Gfx.COLOR_LT_GRAY,Gfx.COLOR_DK_GRAY);
       dc.drawText(20,-2,Gfx.FONT_XTINY,"battery",Gfx.TEXT_JUSTIFY_CENTER);
       dc.drawText(dx-20,-2,Gfx.FONT_XTINY,"gps",Gfx.TEXT_JUSTIFY_CENTER);
       dc.clearClip();
    }

    function onUpdate(dc)
    {
       bg=false;
       if(getBackgroundColor()==Gfx.COLOR_BLACK)
       {
          bg=true;
       }

       if(dy<260)
       {
          dc.drawText(dx/2,dy/2, Gfx.FONT_MEDIUM, "needs whole disp.", Gfx.TEXT_JUSTIFY_CENTER);
       }else
       {
       // header
       header(dc);

       // tacho
       tacho(dc,dx/2,110,80);

       // superbars
       cd_bar.plot(dc);
       el_bar.plot(dc);
       hr_bar.plot(dc);
       pw_bar.plot(dc);
       // current values
       setCol(dc,Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);

       dc.drawText(30,   dy/2-12,Gfx.FONT_TINY, tot_time, Gfx.TEXT_JUSTIFY_CENTER);
       dc.drawText(dx-30,dy/2-12,Gfx.FONT_TINY, tot_dist+" km", Gfx.TEXT_JUSTIFY_CENTER);

       dc.drawText(dx-20,dy/2+18,Gfx.FONT_MEDIUM, cadence, Gfx.TEXT_JUSTIFY_CENTER);
       dc.drawText(20,   dy/2+18,Gfx.FONT_MEDIUM, av_cadence, Gfx.TEXT_JUSTIFY_CENTER);

       dc.drawText(dx-20,dy/2+49,Gfx.FONT_MEDIUM, heartrate, Gfx.TEXT_JUSTIFY_CENTER);
       dc.drawText(20,   dy/2+49,Gfx.FONT_MEDIUM, av_heartrate, Gfx.TEXT_JUSTIFY_CENTER);

       dc.drawText(dx-20,dy/2+80,Gfx.FONT_MEDIUM, altitude, Gfx.TEXT_JUSTIFY_CENTER);
       dc.drawText(20,   dy/2+80,Gfx.FONT_MEDIUM, Math.round(grade).toNumber(), Gfx.TEXT_JUSTIFY_CENTER);

       dc.drawText(dx-20,dy/2+111,Gfx.FONT_MEDIUM, Math.round(power).toNumber(), Gfx.TEXT_JUSTIFY_CENTER);
       dc.drawText(20,dy/2+111,Gfx.FONT_MEDIUM, Math.round(av_power).toNumber(), Gfx.TEXT_JUSTIFY_CENTER);

       dc.drawText(dx-20,34,Gfx.FONT_MEDIUM, ascent,Gfx.TEXT_JUSTIFY_CENTER);
       dc.drawText(20,   34,Gfx.FONT_MEDIUM, descent,Gfx.TEXT_JUSTIFY_CENTER);

       dc.drawText(dx/2,dy/2-13,Gfx.FONT_TINY,head_str[head_int],Gfx.TEXT_JUSTIFY_CENTER);
       if(bg)
       {
          dc.setColor(Gfx.COLOR_LT_GRAY,Gfx.COLOR_TRANSPARENT);
       }else
       {
          dc.setColor(Gfx.COLOR_DK_GRAY,Gfx.COLOR_TRANSPARENT);
       }
       dc.drawText(dx-20,dy/2+6,Gfx.FONT_XTINY, "cd (rpm)", Gfx.TEXT_JUSTIFY_CENTER);
       dc.drawText(20,   dy/2+6,Gfx.FONT_XTINY, "av cd", Gfx.TEXT_JUSTIFY_CENTER);

       dc.drawText(dx-20,dy/2+37,Gfx.FONT_XTINY, "hr (bpm)", Gfx.TEXT_JUSTIFY_CENTER);
       dc.drawText(20,   dy/2+37,Gfx.FONT_XTINY, "av hr", Gfx.TEXT_JUSTIFY_CENTER);

       dc.drawText(dx-20,dy/2+68,Gfx.FONT_XTINY, "alt (m)", Gfx.TEXT_JUSTIFY_CENTER);
       dc.drawText(20,   dy/2+68,Gfx.FONT_XTINY, "grd (%)", Gfx.TEXT_JUSTIFY_CENTER);

       dc.drawText(dx-20,dy/2+99,Gfx.FONT_XTINY, "pwr (W)", Gfx.TEXT_JUSTIFY_CENTER);
       dc.drawText(20,dy/2+99,Gfx.FONT_XTINY, "av pwr", Gfx.TEXT_JUSTIFY_CENTER);

       dc.drawText(dx-20,22,Gfx.FONT_XTINY, "asc (m)", Gfx.TEXT_JUSTIFY_CENTER);
       dc.drawText(20,   22,Gfx.FONT_XTINY, "dsc (m)", Gfx.TEXT_JUSTIFY_CENTER);

   }
   }
}
