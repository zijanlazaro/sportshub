/**
 * Team Data Refresh Utility
 * Handles refreshing team data across different pages when coach assignments change
 */

export function refreshTeamData() {
  if (typeof window.loadTeams === 'function') {
    window.loadTeams();
  }
  if (typeof window.loadDashboardData === 'function') {
    window.loadDashboardData();
  }
  if (typeof window.postMessage === 'function') {
    window.postMessage({ type: 'REFRESH_TEAM_DATA' }, window.location.origin);
  }
}

export function setupTeamDataRefreshListener() {
  window.addEventListener('message', (event) => {
    if (event.origin !== window.location.origin) return;
    if (event.data.type === 'REFRESH_TEAM_DATA') {
      if (typeof window.loadTeams === 'function') {
        window.loadTeams();
      }
      if (typeof window.loadDashboardData === 'function') {
        window.loadDashboardData();
      }
    }
  });
}

let refreshTimeout;
export function debouncedRefreshTeamData(delay = 1000) {
  clearTimeout(refreshTimeout);
  refreshTimeout = setTimeout(refreshTeamData, delay);
}
