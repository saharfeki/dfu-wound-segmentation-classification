UI Context

## Theme

The overall visual language is **Trusted Clinic Blue**—a clean, professional, and accessible interface. It features a light, bright background and utilizes large, structural blue color fields (specifically a distinctive, gentle wave pattern on key onboarding screens) and high-contrast blue primary accents. The design focuses on maximizing clarity and trust through soft shadows, rounded surfaces, and clear typography.

## Colors

All components consume these standardized semantic color tokens across Flutter themes and web CSS variables—no hardcoded hex values are permitted in application code.

| **Role**                | **CSS Variable / Token** | **Value (Hex)** | **Applied Context**                                                                              |
| ----------------------- | ------------------------ | --------------- | ------------------------------------------------------------------------------------------------ |
| **Page background**     | `--bg-base`              | `#FFFFFF`       | Bright white, used for maximizing content readability.                                           |
| **Header Surface**      | `--bg-header`            | `#2D60DB`       | The primary, distinctive blue used for the top wave banner on onboarding screens.                |
| **Surface Raised (L1)** | `--bg-surface`           | `#FFFFFF`       | Input fields, cards, and modal dialog containers.                                                |
| **Primary text**        | `--text-primary`         | `#212B3B`       | Dark charcoal blue, used for all main titles, body text, and labels.                             |
| **Muted text**          | `--text-muted`           | `#6B778B`       | Medium grey, used for subtitles, placeholer text, and metadata.                                  |
| **Primary accent**      | `--accent-primary`       | `#2D60DB`       | Vivid clinical blue, used for primary buttons, active icons, and important interactive elements. |
| **Accent Text**         | `--text-accent`         | `#FFFFFF`       | White, used specifically on dark blue surfaces (e.g., buttons, banners).                         |
| **Divider / Border**    | `--border-default`       | `#E0E6F2`       | Ultra-light grey, used for structural separation and muted lines.                                |
| **Rating / Highlight**  | `--state-rating`         | `#FBBF24`       | Yellow/Amber, used for the star rating icon.                                                     |

## Typography

The typography system prioritizes clarity and immediate scannability. All text uses clean sans-serif fonts.

| **Role**                     | **Font Family**                   | **Variable / Flutter Style** | **Applied Context**                                                        |
| ---------------------------- | --------------------------------- | ---------------------------- | -------------------------------------------------------------------------- |
| **UI text / UI Labels**      | Inter / System Sans               | `--font-sans`                | Navigation, labels, patient metadata, and standard interface text.         |
| **Section Titles / Metrics** | Inter (Medium/Bold) / System Sans | `--font-header`              | App title ("MedConnect"), screen titles, patient names, and large metrics. |

## Border Radius

Strictly defined large corner radii maintain a consistent, friendly, and accessible aesthetic. The large buttons are specifically very soft.

| **Context**                          | **Class / Design Token**                    | **Value (Hex)** | **Applied Elements**                                               |
| ------------------------------------ | ------------------------------------------- | --------------- | ------------------------------------------------------------------ |
| **Inline / Small UI**                | `rounded-lg` / `BorderRadius.circular(10)`  | `10px`          | Small input fields, segmented controls, and chips.                 |
| **Cards / Input Fields**             | `rounded-xl` / `BorderRadius.circular(16)`  | `16px`          | Standard patient/doctor cards, main inputs (username/password).    |
| **Large Buttons / Special Surfaces** | `rounded-2xl` / `BorderRadius.circular(24)` | `24px`          | Main "Login" and "Book Appointment" buttons, unique info overlays. |

## Component Library

- **Flutter Client**: Custom modular widget library built on top of `Material3`. This includes custom widgets for the branded blue wave header and heavily rounded, soft buttons.
- **Web Interface**: `shadcn/ui` built on top of `Tailwind CSS`. New components are added strictly via the `shadcn` CLI to preserve accessibility primitives.

## Layout Patterns

- **Diagnostic Workbench (Main View)**: Full-viewport 3-column split layout on Web:
  - *Left Sidebar (280px fixed)*: Profile summary, model status, and navigation menu.
  - *Center Viewport (Flex canvas)*: Clear, stacked diagnostic results and image canvas.
  - *Right Sidebar (340px fixed)*: Clinical recommendations, previous history comparison, and action buttons.
- **Onboarding / Authentication Screen**: Featured top blue wave banner (`--bg-header`), large application logo, followed by stacked input fields, a large rounded login button, and a central social login selection grid.
- **Top Bar Header**: Clear white navbar (`--bg-base`), containing patient breadcrumbs, organizational ID, and profile access.

## Icons

- **Mobile (Flutter)**: `Lucide Icons` via `lucide_icons` package (stroke width: `1.5px`).
- **Web**: `Lucide React` (`lucide-react`).
- **Sizing Standards**:
  - `18px` (`h-4 w-4`) — Inline status badges and metadata labels.
  - `22px` (`h-5 w-5`) — Standard interactive buttons, toolbar actions, and tab items.
  - `26px` (`h-6 w-6`) — Primary viewfinder controls, floating action triggers, and branded app icons.