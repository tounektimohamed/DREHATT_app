import 'package:DREHATT_app/landing/views/ManageCarouselItemsPage.dart';
import 'package:DREHATT_app/screens2/jeojson/DrawShape.dart';
import 'package:DREHATT_app/screens2/jeojson/DrawShape2.dart';
import 'package:DREHATT_app/screens2/jeojson/formhtml.dart';
import 'package:DREHATT_app/screens2/jeojson/sigweb.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_timeline_calendar/timeline/flutter_timeline_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:DREHATT_app/screens2/jeojson/ai.dart';

// Importer d'autres fichiers nécessaires
import 'package:DREHATT_app/screens2/admin/AccessLogsPage.dart';
import 'package:DREHATT_app/screens2/users/ClaimsListPage.dart';
import 'package:DREHATT_app/screens2/permis%20de%20bati/HousingApplicationForm.dart';
import 'package:DREHATT_app/screens2/permis%20de%20bati/HousingApplicationListPage.dart';
import 'package:DREHATT_app/screens2/jeojson/SubscribersPage.dart';
import 'package:DREHATT_app/screens2/news/gerenews.dart';
import 'package:DREHATT_app/screens2/users/User%20Management.dart';
import '../login_signup/account_settings.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ValueNotifier<CalendarDateTime> _selectedDate =
      ValueNotifier<CalendarDateTime>(
    CalendarDateTime(
      year: DateTime.now().year,
      month: DateTime.now().month,
      day: DateTime.now().day,
    ),
  );

  int _currentIndex = 0;
  final PageController _pageController = PageController();
  User? currentUser = FirebaseAuth.instance.currentUser;

  // Catégories pour organiser les fonctionnalités
  final List<Map<String, dynamic>> _geoItems = [
    {
      'title': 'Suivi des PAUS',
      'image': 'lib/assets/icons/me/isens_thumb-removebg-preview.png',
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SigWeb(title: 'Sig web'),
          ),
        );
      },
      'color': const Color(0xFF48BB78),
    },
    {
      'title': 'Permis de construire',
      'image': 'lib/assets/icons/me/permis_debati-removebg-preview.png',
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapDrawingPage(),
          ),
        );
      },
      'color': const Color(0xFF4299E1),
    },
    {
      'title': 'Suivi des plans de lotissement',
      'image': 'lib/assets/icons/me/realisations-16918-removebg-preview.png',
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CombinedMapPage(),
          ),
        );
      },
      'color': const Color(0xFFED8936),
    },
    {
      'title': 'Ajouter tiff',
      'image': 'lib/assets/icons/me/ajout des images.png',
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddHtmlFormPage(),
          ),
        );
      },
      'color': const Color(0xFF9F7AEA),
    },
    {
      'title': 'Test d\'images',
      'image': 'lib/assets/icons/me/camera.png', // choisis une icône ou image
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TestImagePage(),
          ),
        );
      },
      'color': const Color(0xFF3A7FD5),
    },
  ];

  final List<Map<String, dynamic>> _managementItems = [
    {
      'title': 'Gestion des utilisateurs',
      'image': 'lib/assets/icons/me/menagment.gif',
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UserManagement(),
          ),
        );
      },
      'color': const Color(0xFFF56565),
    },
    {
      'title': 'Journaux d\'accès',
      'image': 'lib/assets/icons/me/admin1.gif',
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AccessLogsPage(),
          ),
        );
      },
      'color': const Color(0xFF38B2AC),
    },
    {
      'title': 'Gestion des nouvelles',
      'image': 'lib/assets/icons/me/news1.gif',
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GereListPage(),
          ),
        );
      },
      'color': const Color(0xFFED64A6),
    },
    {
      'title': 'Gestion des abonnés',
      'image': 'lib/assets/icons/me/subscribers.gif',
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SubscribersPage(),
          ),
        );
      },
      'color': const Color(0xFF667EEA),
    },
  ];

  final List<Map<String, dynamic>> _requestItems = [
    {
      'title': 'Liste des réclamations',
      'image': 'lib/assets/icons/me/admin4.gif',
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClaimsListPage(),
          ),
        );
      },
      'color': const Color(0xFFECC94B),
    },
    {
      'title': 'Demandes de logement',
      'image': 'lib/assets/icons/me/maps.gif',
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HousingApplicationListPage(),
          ),
        );
      },
      'color': const Color(0xFF4FD1C5),
    },
    {
      'title': 'Gérer le carrousel',
      'image': 'lib/assets/icons/me/G-carrousel.png',
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManageCarouselItemsPage(),
          ),
        );
      },
      'color': const Color(0xFFFC8181),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 900;
          bool isTablet =
              constraints.maxWidth > 600 && constraints.maxWidth <= 900;

          return Column(
            children: [
              // En-tête amélioré
              _buildHeader(isDesktop),

              // Contenu principal avec navigation
              Expanded(
                child: Row(
                  children: [
                    // Navigation latérale pour desktop
                    if (isDesktop) _buildDesktopNavigation(),

                    // Contenu principal
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        children: [
                          // Page Tableau de bord
                          _buildDashboardContent(isDesktop, isTablet),

                          // Page Géospatial
                          _buildCategoryPage(
                              "Géospatial", _geoItems, isDesktop, isTablet),

                          // Page Gestion
                          _buildCategoryPage(
                              "Gestion", _managementItems, isDesktop, isTablet),

                          // Page Demandes
                          _buildCategoryPage(
                              "Demandes", _requestItems, isDesktop, isTablet),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      // Navigation inférieure pour mobile
      bottomNavigationBar: MediaQuery.of(context).size.width < 600
          ? _buildBottomNavigationBar()
          : null,
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 20,
        vertical: isDesktop ? 20 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'lib/assets/icons/me/logo.png',
            height: isDesktop ? 60 : 40,
          ),
          if (!isDesktop)
            Text(
              'Tableau de bord',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.grey),
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPageUI(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: isDesktop ? 22 : 18,
                  backgroundImage: currentUser?.photoURL != null
                      ? NetworkImage(currentUser!.photoURL!)
                      : null,
                  backgroundColor: const Color(0xFF3A7FD5),
                  child: currentUser?.photoURL == null
                      ? const Icon(Icons.person_outline, color: Colors.white)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNavigation() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Administration',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D3748),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildNavItem('Tableau de bord', Icons.dashboard, 0),
          _buildNavItem('Géospatial', Icons.map, 1),
          _buildNavItem('Gestion', Icons.people, 2),
          _buildNavItem('Demandes', Icons.request_page, 3),
            const TestImagePage(), // 🚀 nouvelle page ajoutée ici

          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: Text(
              'Paramètres',
              style: GoogleFonts.roboto(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPageUI(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, IconData icon, int index) {
    return ListTile(
      leading: Icon(icon,
          color:
              _currentIndex == index ? const Color(0xFF3A7FD5) : Colors.grey),
      title: Text(
        title,
        style: GoogleFonts.roboto(
          color: _currentIndex == index
              ? const Color(0xFF3A7FD5)
              : Colors.grey[700],
          fontWeight:
              _currentIndex == index ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      onTap: () {
        setState(() {
          _currentIndex = index;
          _pageController.jumpToPage(index);
        });
      },
    );
  }

  Widget _buildDashboardContent(bool isDesktop, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section de bienvenue
          _buildWelcomeSection(isDesktop),

          const SizedBox(height: 24),

          // Calendrier
          _buildCalendarSection(isDesktop, isTablet),

          const SizedBox(height: 32),

          // Accès rapide aux catégories
          Text(
            'Accès rapide',
            style: GoogleFonts.roboto(
              fontSize: isDesktop ? 22 : 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),

          // Cartes de catégories
          if (isDesktop || isTablet)
            Row(
              children: [
                Expanded(
                    child: _buildCategoryCard(
                        'Géospatial', Icons.map, const Color(0xFF48BB78), 1)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildCategoryCard(
                        'Gestion', Icons.people, const Color(0xFF4299E1), 2)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildCategoryCard('Demandes', Icons.request_page,
                        const Color(0xFFED8936), 3)),
              ],
            )
          else
            Column(
              children: [
                _buildCategoryCard(
                    'Géospatial', Icons.map, const Color(0xFF48BB78), 1),
                const SizedBox(height: 12),
                _buildCategoryCard(
                    'Gestion', Icons.people, const Color(0xFF4299E1), 2),
                const SizedBox(height: 12),
                _buildCategoryCard(
                    'Demandes', Icons.request_page, const Color(0xFFED8936), 3),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryPage(String title, List<Map<String, dynamic>> items,
      bool isDesktop, bool isTablet) {
    int crossAxisCount;
    if (isDesktop) {
      crossAxisCount = 4;
    } else if (isTablet) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: isDesktop ? 28 : 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
            children: items.map((item) {
              return _buildDashboardItem(
                item['title'],
                item['image'],
                item['color'],
                () => item['onTap'](context),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour, Admin',
          style: GoogleFonts.roboto(
            fontSize: isDesktop ? 28 : 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Voici un aperçu de vos activités',
          style: GoogleFonts.roboto(
            fontSize: isDesktop ? 16 : 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection(bool isDesktop, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calendrier',
            style: GoogleFonts.roboto(
              fontSize: isDesktop ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
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
              dayFontSize: isDesktop ? 16 : 14,
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
          const SizedBox(height: 16),
          Text(
            _selectedDate.value.toString().substring(0, 10),
            style: GoogleFonts.roboto(
              fontSize: isDesktop ? 18 : 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3A7FD5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      String title, IconData icon, Color color, int pageIndex) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = pageIndex;
            _pageController.jumpToPage(pageIndex);
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Voir détails',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardItem(
      String title, String imagePath, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  imagePath,
                  height: 32,
                  width: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
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

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
          _pageController.jumpToPage(index);
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF3A7FD5),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Géospatial',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Gestion',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.request_page),
          label: 'Demandes',
        ),
      ],
    );
  }
}
