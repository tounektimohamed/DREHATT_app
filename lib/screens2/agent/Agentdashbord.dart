import 'package:DREHATT_app/screens2/jeojson/formhtml.dart';
import 'package:DREHATT_app/screens2/users/ClaimsListPage.dart';
import 'package:DREHATT_app/screens2/jeojson/DrawShape2.dart';
import 'package:DREHATT_app/screens2/permis%20de%20bati/HousingApplicationListPage.dart';
import 'package:DREHATT_app/screens2/news/add_news_screen.dart';
import 'package:DREHATT_app/screens2/news/gerenews.dart';
import 'package:DREHATT_app/screens2/jeojson/sigweb.dart';
import 'package:DREHATT_app/screens2/jeojson/DrawShape.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_timeline_calendar/timeline/flutter_timeline_calendar.dart';
import '../login_signup/account_settings.dart';

class AgentDashboard extends StatefulWidget {
  const AgentDashboard({Key? key}) : super(key: key);

  @override
  _AgentDashboardState createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  final ValueNotifier<CalendarDateTime> _selectedDate =
      ValueNotifier<CalendarDateTime>(
    CalendarDateTime(
      year: DateTime.now().year,
      month: DateTime.now().month,
      day: DateTime.now().day,
    ),
  );

  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isLargeScreen = constraints.maxWidth > 1000;
          bool isMediumScreen = constraints.maxWidth > 600 && constraints.maxWidth <= 1000;
          bool isSmallScreen = constraints.maxWidth <= 600;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête amélioré avec dégradé de couleur
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 40 : (isMediumScreen ? 30 : 20),
                    vertical: isLargeScreen ? 25 : (isMediumScreen ? 20 : 15),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF3A7FD5),
                        const Color(0xFF2D68A9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'lib/assets/icons/me/logo.png',
                        height: isLargeScreen ? 70 : (isMediumScreen ? 50 : 40),
                        filterQuality: FilterQuality.high,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPageUI(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: isLargeScreen ? 22 : (isMediumScreen ? 18 : 16),
                            backgroundImage: currentUser?.photoURL != null
                                ? NetworkImage(currentUser!.photoURL!)
                                : null,
                            backgroundColor: Colors.white,
                            child: currentUser?.photoURL == null
                                ? Icon(Icons.person_outline, 
                                    color: Color(0xFF3A7FD5),
                                    size: isLargeScreen ? 24 : 20)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Section de bienvenue
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isLargeScreen ? 40 : (isMediumScreen ? 30 : 20),
                    isLargeScreen ? 30 : 20,
                    isLargeScreen ? 40 : (isMediumScreen ? 30 : 20),
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, Agent',
                        style: GoogleFonts.roboto(
                          fontSize: isLargeScreen ? 28 : (isMediumScreen ? 24 : 20),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Bienvenue sur votre tableau de bord',
                        style: GoogleFonts.roboto(
                          fontSize: isLargeScreen ? 16 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Calendrier dans un card avec design amélioré
                Padding(
                  padding: EdgeInsets.all(isLargeScreen ? 30 : (isMediumScreen ? 20 : 16)),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calendrier',
                            style: GoogleFonts.roboto(
                              fontSize: isLargeScreen ? 20 : 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                          SizedBox(height: 16),
                          TimelineCalendar(
                            calendarType: CalendarType.GREGORIAN,
                            calendarOptions: CalendarOptions(
                              viewType: ViewType.DAILY,
                              toggleViewType: true,
                              headerMonthElevation: 0,
                              headerMonthBackColor: const Color(0xFFF7FAFC),
                            ),
                            dayOptions: DayOptions(
                              compactMode: true,
                              dayFontSize: isLargeScreen ? 16 : 14,
                              weekDaySelectedColor: const Color(0xFF3A7FD5),
                              selectedBackgroundColor: const Color(0xFF3A7FD5),
                              disableDaysBeforeNow: false,
                              unselectedBackgroundColor: Colors.white,
                            ),
                            headerOptions: HeaderOptions(
                              weekDayStringType: WeekDayStringTypes.SHORT,
                              monthStringType: MonthStringTypes.FULL,
                              backgroundColor: const Color(0xFFF7FAFC),
                              headerTextColor: const Color(0xFF2D3748),
                            ),
                            onChangeDateTime: (date) {
                              setState(() {
                                _selectedDate.value = date;
                              });
                            },
                            onDateTimeReset: (p0) {
                              setState(() {
                                _selectedDate.value = CalendarDateTime(
                                  year: DateTime.now().year,
                                  month: DateTime.now().month,
                                  day: DateTime.now().day,
                                );
                              });
                            },
                            dateTime: _selectedDate.value,
                          ),
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF3A7FD5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today, 
                                    size: 18, 
                                    color: Color(0xFF3A7FD5)),
                                SizedBox(width: 8),
                                Text(
                                  _selectedDate.value.toString().substring(0, 10),
                                  style: GoogleFonts.roboto(
                                    fontSize: isLargeScreen ? 18 : 16,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF3A7FD5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Section des fonctionnalités avec titre
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isLargeScreen ? 40 : (isMediumScreen ? 30 : 20),
                    0,
                    isLargeScreen ? 40 : (isMediumScreen ? 30 : 20),
                    10,
                  ),
                  child: Text(
                    'Fonctionnalités',
                    style: GoogleFonts.roboto(
                      fontSize: isLargeScreen ? 22 : 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                ),

                // Grille des éléments du tableau de bord avec design amélioré
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 30 : (isMediumScreen ? 20 : 16),
                  ),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isLargeScreen
                        ? 4
                        : isMediumScreen
                            ? 3
                            : 2,
                    crossAxisSpacing: isLargeScreen ? 20 : 16,
                    mainAxisSpacing: isLargeScreen ? 20 : 16,
                    childAspectRatio: 0.85,
                    children: [
                      _buildDashboardItem(
                        context,
                        'Suivi des PAUS et plans de lotissement',
                        'lib/assets/icons/me/isens_thumb-removebg-preview.png',
                        Color(0xFF48BB78),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SigWeb(title: 'Sig web'),
                            ),
                          );
                        },
                      ),
                      _buildDashboardItem(
                        context,
                        'Permis de construire',
                        'lib/assets/icons/me/permis_debati-removebg-preview.png',
                        Color(0xFF4299E1),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapDrawingPage(),
                            ),
                          );
                        },
                      ),
                    
                      _buildDashboardItem(
                        context,
                        'Ajouter tiff',
                        'lib/assets/icons/me/ajout des images.png',
                        Color(0xFF9F7AEA),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddHtmlFormPage(),
                            ),
                          );
                        },
                      ),
                      _buildDashboardItem(
                        context,
                        'Voir les actualités',
                        'lib/assets/icons/me/news1.gif',
                        Color(0xFFED64A6),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GereListPage(),
                            ),
                          );
                        },
                      ),
                      _buildDashboardItem(
                        context,
                        'Page des réclamations',
                        'lib/assets/icons/me/admin4.gif',
                        Color(0xFFECC94B),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClaimsListPage(),
                            ),
                          );
                        },
                      ),
                      _buildDashboardItem(
                        context,
                        'Liste des demandes de permis',
                        'lib/assets/icons/me/admin1.gif',
                        Color(0xFF4FD1C5),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HousingApplicationListPage(),
                            ),
                          );
                        },
                      ),
                      // _buildDashboardItem(
                      //   context,
                      //   'Ajouter une actualité',
                      //   'lib/assets/icons/me/news.gif',
                      //   Color(0xFF667EEA),
                      //   () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => const AddNewsScreen(),
                      //       ),
                      //     );
                      //   },
                      // ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context, String title, String iconPath,
      Color color, VoidCallback onPressed) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  iconPath,
                  width: 32,
                  height: 32,
                  color: color,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2D3748),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}